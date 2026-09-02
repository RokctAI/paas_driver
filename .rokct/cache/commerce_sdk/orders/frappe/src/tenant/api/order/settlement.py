# Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

"""Seller settlement + refund clawback for marketplace Orders.

Until now nothing moved money when an Order was Delivered: seller
"earnings" were read-time SQL sums (seller_reports.py), the deliveryman
kept COD cash with no ledger record, and accepting a refund moved
nothing. This module posts the real wallet entries.

``settle_order(order)`` fires from the Order controller's ``on_update``
once an order is BOTH ``status == "Delivered"`` and
``payment_status == "Paid"`` (whichever transition lands second) and has
not been settled yet. In one DB transaction it:

1. credits the shop owner's Wallet with the ITEMS portion of the order
   (``total_price - delivery_fee - service_fee``);
2. debits the shop owner's Wallet the marketplace commission —
   ``Shop.percentage`` applied to that same items portion (deliberately
   NOT the stored ``Order.commission_fee``, which is computed on the
   full total including delivery and service fees) — and records it as
   an ``Order Commission`` row so the commission finally exists as a
   real document;
3. credits the deliveryman's Wallet with the full ``delivery_fee``
   (always-commission model), lazily creating his Wallet row exactly
   like zones' parcel flow (driver_parcel.py `_get_or_create_wallet`),
   and debits back the DELIVERY commission — a percentage of the
   delivery fee, resolved per-driver with a platform-wide default (see
   ``_resolve_delivery_commission_rate``) and recorded as a second
   Order Commission row (type "Delivery");
4. for cash (COD) orders, debits the deliveryman's Wallet by the gross
   cash he collected (``cod_collected_amount``, falling back to
   ``total_price``) — he keeps the physical cash, negative balances are
   allowed, mirroring the parcel COD precedent
   (driver_parcel.py:236-240).

``settle_delivery_callout(order)`` fires from the seller's
collected-in-person conversion (merchants `seller_order.py`,
``convert_delivery_to_collected``): a delivery order the customer turned
up for keeps its delivery fee and pays it to the driver who had already
been dispatched, gross fee plus delivery-commission bill, exactly as
this settlement would have. The conversion runs it and clears
``deliveryman`` BEFORE writing the order to Delivered — with the
assignment still set, ``settle_order`` would credit the same fee again
and the driver would be paid twice.

``apply_refund_clawback(refund)`` fires from
``update_seller_order_refund`` when a refund request is Accepted: it
credits the buyer with what the platform actually collected (never
more), debits the shop by the refund minus a proportional commission
reversal (recorded on the Order Commission row), and leaves the
deliveryman's delivery-fee credit alone. Orders whose payment was never
collected (e.g. an uncollected COD or a "Credit" order) credit nobody.

``auto_pay_credit_orders(user)`` pays the user's outstanding "Credit"
orders from their wallet, oldest first, full order amounts only — fired
from the Order controller after a credit-collection top-up lands (see
its own docstring for the FIFO / no-overdraw / re-entrancy rules).

``settle_credit_delivery(order)`` fires when an order is Delivered
while still ``payment_status == "Credit"``: the driver and the
platform get their shares immediately and the SHOP fronts all of it
(so neither carries credit risk) — shop owner debited the
``delivery_fee`` (driver credited it minus the delivery commission),
the item commission and the ``service_fee``; the order is marked
``credit_settled``. When the order later becomes Paid and
``settle_order`` runs, a credit-settled order credits the shop the
FULL ``total_price`` — recouping everything fronted — and touches
nobody else. If the credit is never repaid, the shop alone is out.

Concurrency follows pay's transfer.py: every Wallet row involved is
locked with ``for_update`` in sorted (deterministic) name order before
any balance is read or written, and the Order / Order Refund row itself
is re-read under a row lock so two concurrent saves cannot both settle
(the ``settled`` / ``clawback_settled`` doc flags are the idempotency
guards, precedent: zones ``cod_settled``, driver_parcel.py:200-206).
Everything rides the request's DB transaction — no explicit commit on
purpose, so any throw rolls the status write and every balance move
back together (parcel precedent, driver_parcel.py:232-235).

Wallet helpers are reimplemented locally in the parcel-flow style
rather than imported from pay's payment.py: they are private helpers of
another SDK's module and driver_parcel.py documents the same deliberate
reimplementation. Every move writes a Wallet History row AND shifts the
legacy ``User.wallet_balance`` mirror, which two code paths still read
as authority (WhatsApp checkout balance check, repeating-order
ringfencing).
"""

import frappe

# Same tolerance zones uses when comparing collected cash to the order
# total (driver_order.py COD_AMOUNT_EPSILON).
AMOUNT_EPSILON = 1e-6


def _get_or_create_wallet(user):
    """Fetch or lazily create a user's Wallet ledger doc.

    Same pattern as zones' driver_parcel.py `_get_or_create_wallet` and
    commerce's deposit_to_wallet: the Wallet doctype (uuid/user/balance)
    is created on first use. Reimplemented locally on purpose.
    """
    wallet_name = frappe.db.get_value("Wallet", {"user": user}, "name")
    if not wallet_name:
        return frappe.get_doc(
            {"doctype": "Wallet", "user": user, "balance": 0}
        ).insert(ignore_permissions=True)
    return frappe.get_doc("Wallet", wallet_name)


def _shift_legacy_user_balance(user, delta):
    """Mirror a wallet movement into the legacy ``User.wallet_balance``
    custom field (delta-based, never overwrite — commerce's
    repeating-order ringfencing moves funds on this same field and an
    overwrite would silently undo an active ringfence). Same contract
    as pay's payment.py `_shift_legacy_user_balance`.
    """
    if not delta:
        return
    if not frappe.get_meta("User").has_field("wallet_balance"):
        return
    current = frappe.db.get_value("User", user, "wallet_balance") or 0.0
    frappe.db.set_value(
        "User",
        user,
        "wallet_balance",
        float(current) + float(delta),
        update_modified=False,
    )


def _record_wallet_history(wallet_name, transaction_type, amount, desc):
    """One audit row per wallet movement — parcel-COD style: the amount
    is SIGNED (debits negative) so direction is auditable, status
    "Paid" (driver_parcel.py:245-271).
    """
    frappe.get_doc(
        {
            "doctype": "Wallet History",
            "wallet": wallet_name,
            "transaction_type": transaction_type,
            "amount": amount,
            "status": "Paid",
            "description": desc,
        }
    ).insert(ignore_permissions=True)


def _is_cash_order(order):
    """True when the order is paid via the cash gateway.

    Local reimplementation of zones' `_split_order_transactions`
    classifier (driver_order.py:118-141) — commerce must not import
    zones: a linked Transaction whose PaaS Payment Gateway's
    ``gateway_controller`` is "cash" (case-insensitive) marks the order
    as cash; so does a recorded ``cod_collected_amount`` (WhatsApp COD
    orders carry no Transaction row at all).
    """
    if float(order.get("cod_collected_amount") or 0) > 0:
        return True
    rows = frappe.get_all(
        "Transaction",
        filters={"payable_type": "Order", "payable_id": order.name},
        fields=["name", "payment_gateway", "status"],
    )
    for row in rows:
        if (row.get("status") or "") == "Canceled":
            # Superseded: e.g. the stale cash Transaction of an order
            # that was converted to Credit and later wallet auto-paid
            # (auto_pay_credit_orders cancels it). It must not classify
            # the order as cash — the deliveryman never kept that cash,
            # so settlement must not debit him the gross.
            continue
        controller = None
        if row.get("payment_gateway"):
            controller = frappe.db.get_value(
                "PaaS Payment Gateway",
                row.get("payment_gateway"),
                "gateway_controller",
            )
        if controller and str(controller).strip().lower() == "cash":
            return True
    return False


def _platform_commission_default(fieldname):
    """Platform-wide default rate from the Commission Settings single
    (0 when the doctype is not installed or the field is unset)."""
    if not frappe.db.exists("DocType", "Commission Settings"):
        return 0.0
    return float(
        frappe.db.get_single_value("Commission Settings", fieldname) or 0
    )


def _resolve_item_commission_rate(shop_percentage):
    """Item-commission rate, platform-wide default with per-shop
    override. Resolution order:

    1. ``Shop.percentage`` when set and nonzero (today's behavior kept:
       the shop's own rate is what gets billed);
    2. ``Commission Settings.item_commission_percent``;
    3. 0.

    A shop cannot override to exactly 0% while a platform default is
    set — 0/unset ``Shop.percentage`` has always meant "no shop-level
    rate", and that reading is preserved.
    """
    rate = float(shop_percentage or 0)
    if rate:
        return rate
    return _platform_commission_default("item_commission_percent")


def _resolve_delivery_commission_rate(deliveryman):
    """Delivery-commission rate for a driver, platform-wide default
    with per-driver override. Resolution order:

    1. the driver's Deliveryman Profile when its
       ``override_delivery_commission`` box is checked —
       ``delivery_commission_percent`` is then used verbatim, so an
       explicit 0% (driver keeps the whole fee) and 100% (salaried
       driver: the platform takes the whole fee) are both expressible;
    2. ``Commission Settings.delivery_commission_percent`` (nonzero);
    3. the legacy zones ``DeliveryMan Settings.default_commission_rate``
       single (nonzero) — the field predates this feature and was
       consumed by nothing; it is kept and wired as the last fallback
       rather than deleted or duplicated;
    4. 0.

    All reads are guarded so orders modules deployed without zones (or
    against an unmigrated Deliveryman Profile) simply fall through.
    """
    if deliveryman and frappe.db.exists("DocType", "Deliveryman Profile"):
        meta = frappe.get_meta("Deliveryman Profile")
        if meta.has_field("override_delivery_commission") and (
            meta.has_field("delivery_commission_percent")
        ):
            row = frappe.db.get_value(
                "Deliveryman Profile",
                {"user": deliveryman},
                [
                    "override_delivery_commission",
                    "delivery_commission_percent",
                ],
                as_dict=True,
            )
            if row and int(row.override_delivery_commission or 0):
                return float(row.delivery_commission_percent or 0)
    rate = _platform_commission_default("delivery_commission_percent")
    if rate:
        return rate
    if frappe.db.exists("DocType", "DeliveryMan Settings"):
        legacy = frappe.db.get_single_value(
            "DeliveryMan Settings", "default_commission_rate"
        )
        if legacy:
            return float(legacy)
    return 0.0


def _lock_wallets(users):
    """Lazily create then row-lock the Wallets of ``users``.

    Locks are taken in sorted (deterministic) Wallet-name order so two
    concurrent settlements touching the same wallets cannot deadlock —
    the transfer.py pattern (pay transfer.py:368-378). Returns
    {user: locked Wallet doc}.
    """
    by_user = {}
    for user in set(users):
        by_user[user] = _get_or_create_wallet(user).name
    locked = {}
    for name in sorted(set(by_user.values())):
        locked[name] = frappe.get_doc("Wallet", name, for_update=True)
    return {user: locked[name] for user, name in by_user.items()}


def _apply_moves(moves):
    """Apply a list of (user, delta, history_type, description) wallet
    moves atomically: lock every Wallet involved (sorted), shift the
    balances, write one Wallet History row per move, and mirror the
    per-user net delta into the legacy User.wallet_balance field.
    Zero-amount moves are dropped.
    """
    moves = [m for m in moves if abs(m[1]) > AMOUNT_EPSILON]
    if not moves:
        return
    wallets = _lock_wallets(u for u, _, _, _ in moves)
    for user, delta, _, _ in moves:
        wallet = wallets[user]
        wallet.balance = float(wallet.balance or 0) + delta
    for wallet in {w.name: w for w in wallets.values()}.values():
        wallet.save(ignore_permissions=True)
    for user, delta, history_type, desc in moves:
        _record_wallet_history(
            wallets[user].name, history_type, delta, desc
        )
    net = {}
    for user, delta, _, _ in moves:
        net[user] = net.get(user, 0.0) + delta
    for user, delta in net.items():
        _shift_legacy_user_balance(user, delta)


def settle_order(order):
    """Post the wallet entries for a Delivered + Paid Order. Idempotent
    via the ``settled`` flag; safe to call from any Order save. Returns
    a small summary dict (``{"settled": False, ...}`` when nothing was
    due).
    """
    if isinstance(order, str):
        order = frappe.get_doc("Order", order)

    if not frappe.get_meta("Order").has_field("settled"):
        # Site not migrated yet: without the flag the settlement cannot
        # be made idempotent, so refuse to move money at all.
        return {"settled": False, "reason": "order-settled-field-missing"}

    if order.status != "Delivered" or order.payment_status != "Paid":
        return {"settled": False, "reason": "not-due"}

    # Serialize on the Order row itself: re-read the flag (and the DB
    # truth of both statuses) under a row lock so two concurrent saves
    # cannot both settle.
    has_credit_flag = frappe.get_meta("Order").has_field("credit_settled")
    lock_fields = ["settled", "status", "payment_status"]
    if has_credit_flag:
        lock_fields.append("credit_settled")
    current = frappe.db.get_value(
        "Order",
        order.name,
        lock_fields,
        as_dict=True,
        for_update=True,
    )
    if not current:
        frappe.throw("Order {0} not found.".format(order.name))
    if current.settled:
        return {"settled": False, "reason": "already-settled"}
    if (
        current.status != "Delivered"
        or current.payment_status != "Paid"
    ):
        return {"settled": False, "reason": "not-due"}
    # Driver and platform already paid at credit delivery, fronted by
    # the shop? Then this repayment settlement credits the shop the
    # FULL total (it recoups everything it fronted) and touches nobody
    # else.
    credit_settled = bool(
        current.get("credit_settled") if has_credit_flag else 0
    )

    shop_values = frappe.db.get_value(
        "Shop", order.shop, ["user", "percentage"], as_dict=True
    )
    if not shop_values or not shop_values.user:
        frappe.throw(
            "Order {0} cannot be settled: its shop has no owner "
            "user.".format(order.name)
        )
    shop_owner = shop_values.user

    total = float(order.total_price or 0)
    delivery_fee = float(order.delivery_fee or 0)
    service_fee = float(order.service_fee or 0)
    # The shop's take is the items side of the order (incl. shop tax,
    # net of discounts); the delivery fee belongs to the deliveryman and
    # the service fee to the platform. Never negative: corrupt fee data
    # must not turn a settlement into a shop debit.
    items_portion = max(total - delivery_fee - service_fee, 0.0)

    # Commission on the ITEMS portion (Takealot-style), NOT on the full
    # total the stored Order.commission_fee uses. calculate_totals and
    # commission_fee are left untouched; the billed figure lives on the
    # Order Commission row. Rate: nonzero Shop.percentage, else the
    # Commission Settings platform default. For a credit-settled order
    # the item commission (and service fee) was already billed at
    # credit delivery, so nothing is billed here.
    rate = _resolve_item_commission_rate(shop_values.percentage)
    commission = (
        0.0 if credit_settled else items_portion * rate / 100.0
    )

    # What the shop receives: normally the items portion (the driver
    # gets his fee, and the platform its commission + service fee, in
    # this same settlement). A credit-settled order already paid the
    # driver AND the platform at credit delivery with the SHOP fronting
    # every share, so the repayment credits the shop the FULL total —
    # nothing deducted — and it recoups exactly what it fronted.
    if credit_settled:
        # The shop recoups everything it fronted — the full total, less
        # whatever it ALREADY holds from a partly-paid POS sale (the
        # till-collected pos_paid_amount never reached the platform, so
        # the repayment passes on only the swept remainder).
        shop_credit = max(total - _pos_paid_of(order), 0.0)
        shop_credit_desc = (
            "Order {0} repayment: credit balance for shop {1}, "
            "recouping the shares fronted at credit delivery".format(
                order.name, order.shop
            )
        )
    else:
        shop_credit = items_portion
        shop_credit_desc = (
            "Order {0} settlement: items total for shop "
            "{1}".format(order.name, order.shop)
        )

    moves = []
    if shop_credit > 0:
        moves.append(
            (
                shop_owner,
                shop_credit,
                "Topup",
                shop_credit_desc,
            )
        )
    if commission > 0:
        moves.append(
            (
                shop_owner,
                -commission,
                "Withdraw",
                "Order {0} marketplace commission ({1}% of "
                "{2})".format(order.name, rate, items_portion),
            )
        )

    deliveryman = order.get("deliveryman")
    delivery_rate = 0.0
    delivery_commission = 0.0
    if deliveryman and delivery_fee > 0 and not credit_settled:
        moves.append(
            (
                deliveryman,
                delivery_fee,
                "Topup",
                "Delivery fee for Order {0}".format(order.name),
            )
        )
        # Delivery commission: billed to the DRIVER as a percentage of
        # the delivery fee (0% = he keeps the whole fee, 100% = the
        # platform takes it all). The gross fee credit above is kept so
        # every move stays on the books; the driver nets
        # delivery_fee - commission.
        delivery_rate = _resolve_delivery_commission_rate(deliveryman)
        delivery_commission = delivery_fee * delivery_rate / 100.0
        if delivery_commission > 0:
            moves.append(
                (
                    deliveryman,
                    -delivery_commission,
                    "Withdraw",
                    "Order {0} delivery commission ({1}% of "
                    "{2})".format(order.name, delivery_rate, delivery_fee),
                )
            )

    if deliveryman and not credit_settled and _is_cash_order(order):
        gross = float(order.get("cod_collected_amount") or 0) or total
        if gross > 0:
            moves.append(
                (
                    deliveryman,
                    -gross,
                    "COD Collection",
                    "Cash collected from customer of Order {0}; the "
                    "deliveryman keeps the physical cash".format(
                        order.name
                    ),
                )
            )

    _apply_moves(moves)

    now = frappe.utils.now_datetime()
    if not credit_settled:
        # Credit-settled orders billed their Item (and Service) rows at
        # credit delivery already; nothing is billed at repayment.
        frappe.get_doc(
            {
                "doctype": "Order Commission",
                "order": order.name,
                "shop": order.shop,
                "commission_type": "Item",
                "party": shop_owner,
                "rate": rate,
                "base_amount": items_portion,
                "commission_amount": commission,
                "reversed_amount": 0,
                "status": "Billed",
                "billed_at": now,
            }
        ).insert(ignore_permissions=True)

    if delivery_commission > 0:
        # Second Order Commission row per order (type Delivery), so the
        # driver's commission exists as a real document exactly like the
        # shop's. Only written when something was actually billed.
        frappe.get_doc(
            {
                "doctype": "Order Commission",
                "order": order.name,
                "shop": order.shop,
                "commission_type": "Delivery",
                "party": deliveryman,
                "rate": delivery_rate,
                "base_amount": delivery_fee,
                "commission_amount": delivery_commission,
                "reversed_amount": 0,
                "status": "Billed",
                "billed_at": now,
            }
        ).insert(ignore_permissions=True)

    frappe.db.set_value(
        "Order",
        order.name,
        {"settled": 1, "settled_at": now},
        update_modified=False,
    )
    order.settled = 1
    order.settled_at = now

    return {
        "settled": True,
        "order": order.name,
        "shop_credit": shop_credit,
        "commission": commission,
        "delivery_fee_credit": (
            delivery_fee
            if deliveryman and delivery_fee > 0 and not credit_settled
            else 0
        ),
        "delivery_commission": delivery_commission,
        "credit_settled_order": credit_settled,
    }



def settle_delivery_callout(order):
    """Pay the assigned deliveryman his CALLOUT when a delivery order is
    collected in person at the counter instead (design strip section 43).

    The customer turned up for an order she had placed for delivery. The
    goods are handed over — never withheld — and the order is converted
    to Pickup. A driver who had already been dispatched still drove for
    it, so the delivery fee is kept (not refunded to her) and paid to
    HIM, exactly as an ordinary settlement would have paid it: the gross
    fee credited, the delivery commission billed back, and the same
    "Delivery" Order Commission row written. Once this has run, the
    conversion clears ``deliveryman`` and the order carries no driver
    into settlement, so ``settle_order`` credits nobody a second time.

    This function deliberately does NOT check the order's ``settled``
    flag. Swallowing an already-settled order here would quietly make
    the two writes interchangeable and hide the hazard below rather than
    remove it; the caller's ordering is the guard, and
    `merchants/frappe/tests/test_collect_in_person.py` pins it on the
    driver's wallet balance.

    ORDERING IS LOAD-BEARING. ``settle_order`` credits the deliveryman
    the FULL ``delivery_fee`` whenever the order reaches Delivered + Paid
    with ``deliveryman`` still set. The conversion must therefore run
    this callout and clear the assignment BEFORE the order is written to
    Delivered — otherwise the driver is paid twice, once here and once by
    the settlement. The ``callout_settled`` flag makes THIS side
    once-only; it cannot defend against a settlement that has already
    run, which is why the caller's ordering, not this flag, is the
    guard.

    Idempotent via the ``callout_settled`` flag, re-read under a row lock
    like ``settle_order``'s ``settled``. Returns a small summary dict
    (``{"settled": False, ...}`` when nothing was due).
    """
    if isinstance(order, str):
        order = frappe.get_doc("Order", order)

    if not frappe.get_meta("Order").has_field("callout_settled"):
        # Site not migrated yet: without the flag the callout cannot be
        # made idempotent, so refuse to move money at all.
        return {"settled": False, "reason": "callout-settled-field-missing"}

    deliveryman = order.get("deliveryman")
    if not deliveryman:
        return {"settled": False, "reason": "no-driver"}

    delivery_fee = float(order.get("delivery_fee") or 0)
    if delivery_fee <= 0:
        return {"settled": False, "reason": "no-fee"}

    has_credit_flag = frappe.get_meta("Order").has_field("credit_settled")
    lock_fields = ["callout_settled"]
    if has_credit_flag:
        lock_fields.append("credit_settled")
    current = frappe.db.get_value(
        "Order",
        order.name,
        lock_fields,
        as_dict=True,
        for_update=True,
    )
    if not current:
        frappe.throw("Order {0} not found.".format(order.name))
    if current.callout_settled:
        return {"settled": False, "reason": "already-settled"}
    if has_credit_flag and current.get("credit_settled"):
        # Credit delivery already paid the driver his share, fronted by
        # the shop; there is no second fee to pay him.
        return {"settled": False, "reason": "credit-settled"}

    delivery_rate = _resolve_delivery_commission_rate(deliveryman)
    delivery_commission = delivery_fee * delivery_rate / 100.0

    moves = [
        (
            deliveryman,
            delivery_fee,
            "Topup",
            "Delivery callout for Order {0}: the customer collected in "
            "person, the fee covers the drive already made".format(
                order.name
            ),
        )
    ]
    if delivery_commission > 0:
        moves.append(
            (
                deliveryman,
                -delivery_commission,
                "Withdraw",
                "Order {0} delivery commission ({1}% of {2})".format(
                    order.name, delivery_rate, delivery_fee
                ),
            )
        )
    _apply_moves(moves)

    now = frappe.utils.now_datetime()
    if delivery_commission > 0:
        frappe.get_doc(
            {
                "doctype": "Order Commission",
                "order": order.name,
                "shop": order.shop,
                "commission_type": "Delivery",
                "party": deliveryman,
                "rate": delivery_rate,
                "base_amount": delivery_fee,
                "commission_amount": delivery_commission,
                "reversed_amount": 0,
                "status": "Billed",
                "billed_at": now,
            }
        ).insert(ignore_permissions=True)

    frappe.db.set_value(
        "Order",
        order.name,
        {"callout_settled": 1, "callout_settled_at": now},
        update_modified=False,
    )
    order.callout_settled = 1
    order.callout_settled_at = now

    return {
        "settled": True,
        "order": order.name,
        "deliveryman": deliveryman,
        "delivery_fee_credit": delivery_fee,
        "delivery_commission": delivery_commission,
    }


def settle_credit_delivery(order):
    """Settle the driver's and the platform's shares at delivery of a
    "Credit" order, all fronted by the shop — the shop alone carries
    the credit risk ("platform and driver always get their share").

    Fires from the Order controller when an order is BOTH
    ``status == "Delivered"`` and ``payment_status == "Credit"``
    (whichever transition lands second — a driver may convert to credit
    before or after marking Delivered). The customer hasn't paid yet,
    but the job is done, so in one locked transaction the shop is
    billed everything that isn't its own money:

    1. shop owner debited the ``delivery_fee``; deliveryman credited it
       in full and debited the delivery commission (resolved rate x
       fee, Order Commission row of type "Delivery") — skipped when
       there is no deliveryman or no fee;
    2. shop owner debited the ITEM commission (rate on the items
       portion), Order Commission row of type "Item", billed NOW;
    3. shop owner debited the ``service_fee`` (the platform's share),
       recorded as an Order Commission row of type "Service" — on
       non-credit orders the service fee never enters the shop wallet,
       so no such row exists there.

    Shop negative balances are allowed. The ``credit_settled`` flag
    makes this once-only and tells the later Paid settlement
    (``settle_order``) to credit the shop the FULL ``total_price`` —
    the shop recoups everything it fronted — and touch nobody else. If
    the credit is never repaid, the shop alone is out: that is the
    design.
    """
    if isinstance(order, str):
        order = frappe.get_doc("Order", order)

    if not frappe.get_meta("Order").has_field("credit_settled"):
        # Site not migrated yet: without the flag this cannot be made
        # idempotent, so refuse to move money at all.
        return {
            "credit_settled": False,
            "reason": "credit-settled-field-missing",
        }

    if order.status != "Delivered" or order.payment_status != "Credit":
        return {"credit_settled": False, "reason": "not-due"}

    # Serialize on the Order row (same lock order as settle_order:
    # order row first, wallets second) and re-check the DB truth.
    current = frappe.db.get_value(
        "Order",
        order.name,
        ["credit_settled", "settled", "status", "payment_status"],
        as_dict=True,
        for_update=True,
    )
    if not current:
        frappe.throw("Order {0} not found.".format(order.name))
    if current.credit_settled:
        return {"credit_settled": False, "reason": "already-settled"}
    if current.settled:
        # The full settlement already ran.
        return {"credit_settled": False, "reason": "order-fully-settled"}
    if (
        current.status != "Delivered"
        or current.payment_status != "Credit"
    ):
        return {"credit_settled": False, "reason": "not-due"}

    shop_values = frappe.db.get_value(
        "Shop", order.shop, ["user", "percentage"], as_dict=True
    )
    if not shop_values or not shop_values.user:
        frappe.throw(
            "Order {0} cannot be credit-settled: its shop has no "
            "owner user.".format(order.name)
        )
    shop_owner = shop_values.user

    total = float(order.total_price or 0)
    delivery_fee = float(order.delivery_fee or 0)
    service_fee = float(order.service_fee or 0)
    items_portion = max(total - delivery_fee - service_fee, 0.0)
    deliveryman = order.get("deliveryman")
    has_driver_leg = bool(deliveryman) and delivery_fee > AMOUNT_EPSILON

    item_rate = _resolve_item_commission_rate(shop_values.percentage)
    item_commission = items_portion * item_rate / 100.0

    delivery_rate = 0.0
    delivery_commission = 0.0
    moves = []
    if has_driver_leg:
        delivery_rate = _resolve_delivery_commission_rate(deliveryman)
        delivery_commission = delivery_fee * delivery_rate / 100.0
        moves.append(
            (
                shop_owner,
                -delivery_fee,
                "Withdraw",
                "Order {0} credit delivery: shop fronts the delivery "
                "fee".format(order.name),
            )
        )
        moves.append(
            (
                deliveryman,
                delivery_fee,
                "Topup",
                "Delivery fee for Order {0} (credit delivery, fronted "
                "by the shop)".format(order.name),
            )
        )
        if delivery_commission > 0:
            moves.append(
                (
                    deliveryman,
                    -delivery_commission,
                    "Withdraw",
                    "Order {0} delivery commission ({1}% of "
                    "{2})".format(
                        order.name, delivery_rate, delivery_fee
                    ),
                )
            )
    if item_commission > 0:
        moves.append(
            (
                shop_owner,
                -item_commission,
                "Withdraw",
                "Order {0} marketplace commission ({1}% of {2}), "
                "billed at credit delivery".format(
                    order.name, item_rate, items_portion
                ),
            )
        )
    if service_fee > AMOUNT_EPSILON:
        moves.append(
            (
                shop_owner,
                -service_fee,
                "Withdraw",
                "Order {0} service fee, billed at credit "
                "delivery".format(order.name),
            )
        )
    _apply_moves(moves)

    now = frappe.utils.now_datetime()
    frappe.get_doc(
        {
            "doctype": "Order Commission",
            "order": order.name,
            "shop": order.shop,
            "commission_type": "Item",
            "party": shop_owner,
            "rate": item_rate,
            "base_amount": items_portion,
            "commission_amount": item_commission,
            "reversed_amount": 0,
            "status": "Billed",
            "billed_at": now,
        }
    ).insert(ignore_permissions=True)
    if delivery_commission > 0:
        frappe.get_doc(
            {
                "doctype": "Order Commission",
                "order": order.name,
                "shop": order.shop,
                "commission_type": "Delivery",
                "party": deliveryman,
                "rate": delivery_rate,
                "base_amount": delivery_fee,
                "commission_amount": delivery_commission,
                "reversed_amount": 0,
                "status": "Billed",
                "billed_at": now,
            }
        ).insert(ignore_permissions=True)
    if service_fee > AMOUNT_EPSILON:
        frappe.get_doc(
            {
                "doctype": "Order Commission",
                "order": order.name,
                "shop": order.shop,
                "commission_type": "Service",
                "party": shop_owner,
                "rate": 0,
                "base_amount": service_fee,
                "commission_amount": service_fee,
                "reversed_amount": 0,
                "status": "Billed",
                "billed_at": now,
            }
        ).insert(ignore_permissions=True)

    frappe.db.set_value(
        "Order",
        order.name,
        {"credit_settled": 1, "credit_settled_at": now},
        update_modified=False,
    )
    order.credit_settled = 1
    order.credit_settled_at = now

    return {
        "credit_settled": True,
        "order": order.name,
        "delivery_fee": delivery_fee if has_driver_leg else 0.0,
        "delivery_commission": delivery_commission,
        "item_commission": item_commission,
        "service_fee": service_fee,
    }


def _cancel_open_transactions(order_id):
    """Mark every non-final payment Transaction on an order Canceled.

    Used when a Credit order is wallet auto-paid: any Transaction still
    Pending/Progress (typically the cash Transaction recorded before the
    order was converted to Credit at the door) is now superseded by the
    wallet payment and must never be collected or classify the order's
    payment method again. Paid and already-Canceled rows are left alone.
    """
    rows = frappe.get_all(
        "Transaction",
        filters={"payable_type": "Order", "payable_id": order_id},
        fields=["name", "status"],
    )
    for row in rows:
        if (row.get("status") or "") not in ("Paid", "Canceled"):
            frappe.db.set_value(
                "Transaction", row.get("name"), "status", "Canceled"
            )


def _wallet_gateway_name():
    """Name of the PaaS Payment Gateway whose ``gateway_controller``
    tag is "wallet" (case-insensitive) — the same controller-tag
    detection pay's ``create_order_transaction`` uses to route wallet
    payments. ``None`` when no wallet gateway is configured; callers
    then record the Transaction without a gateway link, exactly like
    ``create_order_transaction`` does for an unknown gateway id.
    """
    try:
        rows = frappe.get_all(
            "PaaS Payment Gateway",
            fields=["name", "gateway_controller"],
        )
    except Exception:
        return None
    for row in rows:
        controller = row.get("gateway_controller") or row.get("name")
        if str(controller).strip().lower() == "wallet":
            return row.get("name")
    return None


def _has_pos_paid_field():
    """Whether this site's Order doctype carries ``pos_paid_amount``
    (the POS partly-paid contract; guarded like ``credit_settled`` so
    unmigrated sites keep full-total behavior)."""
    try:
        return bool(
            frappe.get_meta("Order").has_field("pos_paid_amount")
        )
    except Exception:
        return False


def _pos_paid_of(row_or_doc):
    """The amount already collected at the till for a POS credit order
    (0 for every other order, and on unmigrated sites)."""
    if not _has_pos_paid_field():
        return 0.0
    try:
        return float(row_or_doc.get("pos_paid_amount") or 0)
    except (TypeError, ValueError):
        return 0.0


def _mint_wallet_paid_transaction(order_id, user, amount):
    """Record the payment Transaction for a wallet-paid order.

    The credit auto-pay sweep debits the wallet and writes Wallet
    History, but without this row the books hold no payment record for
    the sweep — ``_is_cash_order``, refund tooling and the POS
    transaction views all read the ``Transaction`` table. Fields match
    what pay's ``create_order_transaction`` writes for a wallet payment
    (payable_type "Order", status "Paid", type "model", the wallet
    gateway via its controller tag), so a swept order is
    indistinguishable from one paid through the normal endpoint.

    Idempotent, consistent with pay#40's cross-gateway paid guard: an
    order that already carries a Paid Transaction (any gateway) is
    never double-recorded — the existing row's name is returned
    instead. Runs inside the caller's locked transaction so any throw
    rolls the Transaction back together with the wallet debit.
    """
    existing = frappe.db.get_value(
        "Transaction",
        {
            "payable_type": "Order",
            "payable_id": order_id,
            "status": "Paid",
        },
        "name",
    )
    if existing:
        return existing
    fields = {
        "doctype": "Transaction",
        "user": user,
        "payable_type": "Order",
        "payable_id": order_id,
        "amount": amount,
        "status": "Paid",
        "type": "model",
        "performed_at": frappe.utils.now_datetime(),
        "note": "Wallet auto-pay of Credit Order {0}".format(order_id),
    }
    gateway = _wallet_gateway_name()
    if gateway:
        fields["payment_gateway"] = gateway
    return frappe.get_doc(fields).insert(ignore_permissions=True).name


def auto_pay_credit_orders(user):
    """Pay the user's outstanding "Credit" orders from their wallet.

    Fired from the Order controller's ``on_update`` after a credit
    collection lands on the customer's wallet (zones'
    ``confirm_credit_collection`` credits the wallet, then saves the
    Order), and reusable from anywhere as a plain function.

    Strict oldest-first (FIFO): walks the user's
    ``payment_status == "Credit"`` orders in creation order and, while
    the wallet balance covers an order's FULL ``total_price``, debits
    the wallet the full amount — full payments only, never partials —
    and flips the order to Paid via ``doc.save`` so the existing
    settlement hook fires and settles shop/commission/delivery fee
    normally. The walk stops at the first order the balance cannot
    cover: a newer, cheaper order is never paid ahead of an older one,
    and auto-pay never overdraws the wallet (balances that are already
    negative pay nothing).

    Each order is re-read under a row lock right before paying (the
    cross-gateway paid-guard semantics: only an order still "Credit" at
    that instant is eligible), the wallet is locked before its balance
    is read, and the order's superseded open Transactions are Canceled
    before the Paid save so settlement's cash classifier cannot debit
    the deliveryman a gross he never kept. Each debited order also
    mints a Paid wallet ``Transaction`` row
    (``_mint_wallet_paid_transaction``) so the books carry a payment
    record for the sweep, idempotently.

    Re-entrancy: flipping an order Paid re-fires ``Order.on_update``;
    the controller trigger's ``payment_status == "Credit"`` condition
    is then false, and the ``frappe.flags`` latch below stops any other
    nested trigger from starting a second loop inside the first.
    """
    summary = {"user": user, "orders_paid": [], "amount_paid": 0.0}
    if not user:
        return summary

    flags = getattr(frappe, "flags", None)
    if flags is not None:
        if getattr(flags, "rokct_credit_auto_pay_running", False):
            summary["reason"] = "re-entrant-call-skipped"
            return summary
        flags.rokct_credit_auto_pay_running = True
    try:
        candidates = frappe.get_all(
            "Order",
            filters={"user": user, "payment_status": "Credit"},
            fields=["name"],
            order_by="creation asc",
        )
        for row in candidates:
            # Order row FIRST, wallet second — the same lock order as
            # settle_order and zones' confirm_credit_collection, so the
            # three money flows cannot deadlock each other; concurrent
            # auto-pays for one user serialize on the oldest row.
            lock_fields = ["payment_status", "total_price"]
            if _has_pos_paid_field():
                lock_fields.append("pos_paid_amount")
            current = frappe.db.get_value(
                "Order",
                row.name,
                lock_fields,
                as_dict=True,
                for_update=True,
            )
            if not current or current.payment_status != "Credit":
                # Raced: someone else paid or re-flipped it meanwhile.
                continue
            wallet = _lock_wallets([user])[user]
            balance = float(wallet.balance or 0)
            total = float(current.total_price or 0)
            # The credit balance is the total MINUS whatever the till
            # already collected on a partly-paid POS sale
            # (Order.pos_paid_amount; 0 everywhere else). Full-amounts-
            # only semantics are unchanged: the sweep takes the FULL
            # outstanding balance or nothing.
            outstanding = max(total - _pos_paid_of(current), 0.0)
            if outstanding > AMOUNT_EPSILON:
                if balance + AMOUNT_EPSILON < outstanding:
                    # Strict FIFO: never skip ahead to a newer, cheaper
                    # order, and never overdraw the wallet.
                    break
                _apply_moves(
                    [
                        (
                            user,
                            -outstanding,
                            "Payment",
                            "Wallet auto-pay of Credit Order "
                            "{0}".format(row.name),
                        )
                    ]
                )
            _cancel_open_transactions(row.name)
            if outstanding > AMOUNT_EPSILON:
                # Mint the payment record alongside the Wallet History
                # row, before the Paid save so the settlement hook's
                # classifiers already see the wallet Transaction.
                # Idempotent (skips when a Paid Transaction exists) and
                # inside the same locked transaction as the debit.
                _mint_wallet_paid_transaction(row.name, user, outstanding)
            doc = frappe.get_doc("Order", row.name)
            doc.payment_status = "Paid"
            doc.save(ignore_permissions=True)
            summary["orders_paid"].append(row.name)
            summary["amount_paid"] += outstanding
    finally:
        if flags is not None:
            flags.rokct_credit_auto_pay_running = False
    return summary


def _collected_from_buyer(order_row):
    """How much the platform actually collected from the buyer.

    Only a ``payment_status == "Paid"`` order has been collected in
    full (COD confirmation requires the full total before it marks
    Paid; gateway/wallet payments debit the full total). A partial COD
    collection or a "Credit" hand-over left the platform holding
    nothing refundable, so those return 0.
    """
    if (order_row.payment_status or "") != "Paid":
        return 0.0
    return float(order_row.total_price or 0)


def apply_refund_clawback(refund):
    """Post the wallet entries for an APPROVED Order Refund. Idempotent
    via the ``clawback_settled`` flag on the Order Refund row, and
    capped so the cumulative refunds on one order can never exceed what
    the buyer actually paid. Returns a summary dict.
    """
    if isinstance(refund, str):
        refund = frappe.get_doc("Order Refund", refund)

    if not frappe.get_meta("Order Refund").has_field("clawback_settled"):
        return {
            "refunded": False,
            "reason": "refund-clawback-field-missing",
        }

    # Serialize on the refund row: re-read the flag under a row lock so
    # a re-approval racing this one cannot double-move.
    already_done = frappe.db.get_value(
        "Order Refund",
        refund.name,
        "clawback_settled",
        for_update=True,
    )
    if already_done:
        return {"refunded": False, "reason": "already-refunded"}

    order_row = frappe.db.get_value(
        "Order",
        refund.order,
        [
            "name",
            "user",
            "shop",
            "total_price",
            "payment_status",
            "settled",
        ],
        as_dict=True,
        for_update=True,
    )
    if not order_row:
        frappe.throw("Order {0} not found.".format(refund.order))

    total = float(order_row.total_price or 0)
    collected = _collected_from_buyer(order_row)

    # Cumulative cap across multiple refund requests on the same order.
    prior = frappe.get_all(
        "Order Refund",
        filters={
            "order": refund.order,
            "clawback_settled": 1,
            "name": ["!=", refund.name],
        },
        fields=["clawback_amount"],
    )
    already_refunded = sum(
        float(row.get("clawback_amount") or 0) for row in prior
    )

    # The refund request's own amount when it carries one, else the
    # full order total; never more than what is left of what the buyer
    # actually paid.
    requested = float(refund.get("amount") or 0) or total
    buyer_credit = min(requested, collected - already_refunded)
    buyer_credit = max(buyer_credit, 0.0)

    now = frappe.utils.now_datetime()

    commission_reversal = 0.0
    shop_debit = 0.0
    if buyer_credit > AMOUNT_EPSILON and order_row.settled:
        # The shop pays the refund back, minus the proportional share
        # of the commission it was billed at settlement. The
        # deliveryman keeps his delivery-fee credit, so the shop also
        # carries the delivery/service portion of the refund.
        fraction = min(buyer_credit / total, 1.0) if total > 0 else 0.0
        # Only the ITEM commission is reversed on refunds: the delivery
        # happened, so the driver keeps his fee AND its Delivery
        # commission stands. Rows created before commission_type
        # existed are Item commissions (the only kind that existed).
        commission_name = None
        for candidate in frappe.get_all(
            "Order Commission",
            filters={"order": refund.order},
            fields=["name", "commission_type"],
        ):
            if (candidate.get("commission_type") or "Item") == "Item":
                commission_name = candidate.get("name")
                break
        if commission_name:
            commission_doc = frappe.get_doc(
                "Order Commission", commission_name, for_update=True
            )
            billed = float(commission_doc.commission_amount or 0)
            reversed_so_far = float(
                commission_doc.reversed_amount or 0
            )
            commission_reversal = min(
                billed * fraction, billed - reversed_so_far
            )
            commission_reversal = max(commission_reversal, 0.0)
            if commission_reversal > AMOUNT_EPSILON:
                commission_doc.reversed_amount = (
                    reversed_so_far + commission_reversal
                )
                if (
                    commission_doc.reversed_amount
                    >= billed - AMOUNT_EPSILON
                ):
                    commission_doc.status = "Reversed"
                commission_doc.reversed_at = now
                commission_doc.save(ignore_permissions=True)
        shop_debit = max(buyer_credit - commission_reversal, 0.0)

    moves = []
    if buyer_credit > AMOUNT_EPSILON:
        moves.append(
            (
                order_row.user,
                buyer_credit,
                "Refund",
                "Refund for Order {0} ({1})".format(
                    refund.order, refund.name
                ),
            )
        )
    if shop_debit > AMOUNT_EPSILON:
        shop_owner = frappe.db.get_value(
            "Shop", order_row.shop, "user"
        )
        if not shop_owner:
            frappe.throw(
                "Refund for Order {0} cannot be applied: its shop has "
                "no owner user.".format(refund.order)
            )
        moves.append(
            (
                shop_owner,
                -shop_debit,
                "Refund",
                "Refund clawback for Order {0} ({1}): {2} refunded "
                "minus {3} commission reversed".format(
                    refund.order,
                    refund.name,
                    buyer_credit,
                    commission_reversal,
                ),
            )
        )

    _apply_moves(moves)

    frappe.db.set_value(
        "Order Refund",
        refund.name,
        {
            "clawback_settled": 1,
            "clawback_settled_at": now,
            "clawback_amount": buyer_credit,
        },
        update_modified=False,
    )

    return {
        "refunded": buyer_credit > AMOUNT_EPSILON,
        "order": refund.order,
        "buyer_credit": buyer_credit,
        "shop_debit": shop_debit,
        "commission_reversed": commission_reversal,
    }
