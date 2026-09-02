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

from typing import Any, Optional
import frappe
import json
from frappe.model.document import Document
from {app_name}.base.tenant.api.utils import api_response
from {app_name}.base.tenant.api.idempotency import idempotent

# Optional severe-weather annotation for customer-facing order payloads
# (src/weather_notice/ - the orders-module twin of the delivery module's
# per-stop annotation). Guarded: under stub/unpackaged harnesses (or a
# future layout change) the relative import fails and the annotation is
# simply skipped - the weather_notice field is additive and its absence
# is a valid state everywhere.
try:
    from ...weather_notice.weather_notice import (
        order_weather_notice,
        parse_location_dict,
    )
except Exception:  # pragma: no cover - packaged shells always resolve this
    order_weather_notice = None
    parse_location_dict = None


def _annotate_weather(row, location=None):
    """Attach the optional ``weather_notice`` field (the drop-off grid
    cell's active severe-weather heads-up: server-authored calm one-liner
    + severity word + valid window) onto a serialized order dict.

    Additive and guarded: shells without the weather module, a disabled
    master switch, quiet weather and malformed coordinates all leave the
    field ABSENT and the row otherwise untouched. Never raises.
    """
    if order_weather_notice is None or parse_location_dict is None:
        return row
    try:
        parsed = parse_location_dict(
            location if location is not None else row.get("location"))
        if parsed:
            notice = order_weather_notice(
                parsed["latitude"], parsed["longitude"])
            if notice:
                row["weather_notice"] = notice
    except Exception:
        pass
    return row


ADULT_AGE_OF_MAJORITY = 18

# Legacy wire statuses the dart clients speak (list_orders' precedent:
# lowercase legacy strings, matched case-insensitively), mapped onto the
# Order doctype's Select options. 'ready' exists on the doctype since the
# POS create-contract change (seller tills create packed delivery orders
# at Ready); 'on_a_way' has always been the doctype's "Shipped".
_ORDER_STATUS_ALIASES = {
    "new": "New",
    "accepted": "Accepted",
    "ready": "Ready",
    "on_a_way": "Shipped",
    "shipped": "Shipped",
    "delivered": "Delivered",
    "canceled": "Cancelled",
    "cancelled": "Cancelled",
}

# Fallback whitelist when doctype meta is unavailable (stub/test
# contexts) — mirrors the Order doctype's status Select options.
_ORDER_STATUS_OPTIONS = (
    "New",
    "Accepted",
    "Ready",
    "Shipped",
    "Delivered",
    "Cancelled",
    "Paid",
    "Failed",
)


def _normalize_order_status(value):
    """Resolve a client-supplied order status against the REAL status
    whitelist (update_order's meta-options pattern), accepting the dart
    fleet's legacy lowercase wire strings via ``_ORDER_STATUS_ALIASES``.
    Throws on anything that is not a real status.
    """
    normalized = str(value).strip()
    normalized = _ORDER_STATUS_ALIASES.get(normalized.lower(), normalized)
    try:
        valid_statuses = (
            frappe.get_meta("Order").get_field("status").options.split("\n")
        )
    except Exception:
        valid_statuses = list(_ORDER_STATUS_OPTIONS)
    match = next(
        (
            option
            for option in valid_statuses
            if option and option.lower() == normalized.lower()
        ),
        None,
    )
    if match is None:
        frappe.throw(
            "Invalid status. Must be one of {0}".format(
                ", ".join(s for s in valid_statuses if s)
            )
        )
    return match


def _is_pos_order(shop_id: Any) -> bool:
    """
    Discriminates manager-placed (POS) orders from customer checkout.

    The manager app creates orders through the same ``create_order`` cmd,
    but always under the seller's own authenticated session: the session
    user is the Shop's linked ``user`` (the same User->Shop linkage the
    seller order flow resolves via ``_get_seller_shop``), or a System
    Manager acting on the tenant. Customer checkout always runs under the
    customer's own session (or Guest), which never matches the shop's
    linked user. POS orders are exempt from the online age gate because
    the seller performs a face-to-face ID check.
    """
    session_user = frappe.session.user
    if not session_user or session_user == "Guest":
        return False
    if "System Manager" in frappe.get_roles(session_user):
        return True
    if not shop_id:
        return False
    return frappe.db.get_value("Shop", shop_id, "user") == session_user


@frappe.whitelist(allow_guest=True)
@idempotent
def create_order(order_data: Any) -> Any:
    """
    Creates a new order.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    if isinstance(order_data, str):
        order_data = json.loads(order_data)

    # 1. Idempotency Check (Offline UUID)
    offline_uuid = order_data.get("offline_uuid")
    if offline_uuid:
        existing_order = frappe.db.exists(
            "Order", {"offline_uuid": offline_uuid}
        )
        if existing_order:
            return api_response(
                data=frappe.get_doc("Order", existing_order).as_dict(),
                message="Duplicate order detected. Returning existing order.",
            )

    # Check for hierarchical auto-approval
    paas_settings = frappe.get_single("Permission Settings")

    # Validate phone number if required by admin settings
    if paas_settings.require_phone_for_order and not order_data.get("phone"):
        frappe.throw(
            "A phone number is required to create this order.",
            frappe.ValidationError,
        )

    shop = frappe.get_doc("Shop", order_data.get("shop"))

    initial_status = "New"
    if paas_settings.auto_approve_orders and shop.auto_approve_orders:
        initial_status = "Accepted"

    # Seller-origin (POS) orders arrive with the status they already hold
    # on the till — an offline-first sale synced later must not restart at
    # "New" (an in-store sale is already Delivered; a packed
    # send-for-delivery sale is already Ready). The supplied status is
    # honored ONLY for seller-origin sessions (`_is_pos_order`) and is
    # validated against the real status whitelist; customer checkouts keep
    # the forced initial status above.
    supplied_status = order_data.get("status")
    if supplied_status and _is_pos_order(order_data.get("shop")):
        initial_status = _normalize_order_status(supplied_status)

    # If cart_id is provided and order_items is missing, load items from cart
    if order_data.get("cart_id") and not order_data.get("order_items"):
        cart = frappe.get_doc("Cart", order_data.get("cart_id"))
        order_items = []
        for item in cart.items:
            product_doc = frappe.get_doc("Product", item.item)
            order_items.append(
                {
                    "product": item.item,
                    "quantity": item.quantity,
                    "price": item.price or product_doc.price,
                    "alternative_product": item.alternative_product,
                }
            )
        order_data["order_items"] = order_items

    order = frappe.get_doc(
        {
            "doctype": "Order",
            "user": order_data.get("user"),
            "shop": order_data.get("shop"),
            "status": initial_status,
            "delivery_type": order_data.get("delivery_type"),
            "currency": order_data.get("currency"),
            "rate": order_data.get("rate"),
            "delivery_fee": order_data.get("delivery_fee"),
            "waiter_fee": order_data.get("waiter_fee"),
            "tax": order_data.get("tax"),
            "commission_fee": order_data.get("commission_fee"),
            "service_fee": order_data.get("service_fee"),
            "total_discount": order_data.get("total_discount"),
            "coupon_code": order_data.get("coupon_code"),
            "location": order_data.get("location"),
            "address": order_data.get("address"),
            "phone": order_data.get("phone"),
            "username": order_data.get("username"),
            "delivery_date": order_data.get("delivery_date"),
            "delivery_time": order_data.get("delivery_time"),
            "note": order_data.get("note"),
            "offline_uuid": offline_uuid,
        }
    )

    for item in order_data.get("order_items", []):
        product_id = item.get("product")
        quantity = item.get("quantity")
        alt_product_id = item.get("alternative_product")

        # Real-time Stock Check & Auto-Substitution
        is_substituted = 0
        original_product = None

        # Check stock for primary product
        stock_qty = (
            frappe.db.get_value(
                "Stock",
                {"shop": order_data.get("shop"), "product": product_id},
                "quantity",
            )
            or 0
        )

        if stock_qty <= 0 and alt_product_id:
            # Check stock for alternative product
            alt_stock_qty = (
                frappe.db.get_value(
                    "Stock",
                    {
                        "shop": order_data.get("shop"),
                        "product": alt_product_id,
                    },
                    "quantity",
                )
                or 0
            )
            if alt_stock_qty > 0:
                original_product = product_id
                product_id = alt_product_id
                is_substituted = 1

        # Fetch current price for the chosen product (primary or substituted)
        current_price = (
            frappe.db.get_value("Product", product_id, "price") or 0
        )
        cost_price = frappe.db.get_value("Product", product_id, "cost") or 0

        order.append(
            "order_items",
            {
                "product": product_id,
                "quantity": quantity,
                "price": current_price,
                "cost_price": cost_price,
                "alternative_product": alt_product_id,
                "is_substituted": is_substituted,
                "original_product": original_product,
            },
        )

    # 18+ (adults only) age gate — runs after item assembly so substituted
    # products are covered too.
    order_product_ids = [
        row.product for row in order.order_items if row.product
    ]
    contains_adult_items = bool(
        order_product_ids
        and frappe.db.count(
            "Product", {"name": ["in", order_product_ids], "is_adult": 1}
        )
    )
    if contains_adult_items and not _is_pos_order(order_data.get("shop")):
        buyer = order_data.get("user") or frappe.session.user
        birth_date = None
        if (
            frappe.session.user != "Guest"
            and buyer
            and buyer != "Guest"
            and frappe.db.exists("User", buyer)
        ):
            birth_date = frappe.db.get_value("User", buyer, "birth_date")
        if frappe.session.user == "Guest" or not birth_date:
            frappe.throw(
                "AGE_VERIFICATION_REQUIRED: This order contains 18+ "
                "(adults only) items. A verified date of birth on the "
                "buyer's account is required.",
                frappe.ValidationError,
            )
        # Age of majority computed from User.birth_date at order time.
        today = frappe.utils.getdate()
        born = frappe.utils.getdate(birth_date)
        age = today.year - born.year - (
            (today.month, today.day) < (born.month, born.day)
        )
        if age < ADULT_AGE_OF_MAJORITY:
            frappe.throw(
                "UNDERAGE_PURCHASE_BLOCKED: You must be at least 18 years "
                "old to purchase 18+ (adults only) items.",
                frappe.ValidationError,
            )
        order.age_verified = 1
        order.age_verified_at = frappe.utils.now_datetime()
        order.age_verified_by = frappe.session.user

    # Store the quoted total from frontend for refund calculation
    order.quoted_total = order_data.get("quoted_total") or 0

    order.insert(ignore_permissions=True)

    # Surplus Refund Logic (Pay-Max Strategy)
    # If the user authorized/paid more than the final actual total, refund to
    # wallet.
    if order.quoted_total > order.total_price:
        refund_amount = order.quoted_total - order.total_price
        deposit_to_wallet(
            user=order.user,
            amount=refund_amount,
            note=f"Substitution refund for Order {order.name}",
        )

    # Calculate cashback
    if order.total_price:
        # Direct composed tenant module path
        # (merchants/frappe/src/tenant/api/shop/shop.py). The manifest alias
        # {app_name}.api.shop.check_cashback resolves to the same function
        # via the shop package re-export.
        cashback_amount = frappe.call(
            "{app_name}.merchants.tenant.api.shop.shop.check_cashback",
            shop_id=order_data.get("shop"),
            amount=order.total_price,
        )
        order.db_set("cashback_amount", cashback_amount.get("cashback_amount"))

    if order_data.get("coupon_code"):
        coupon = frappe.get_doc(
            "Coupon", {"code": order_data.get("coupon_code")}
        )
        frappe.get_doc(
            {
                "doctype": "Coupon Usage",
                "coupon": coupon.name,
                "user": order.user,
                "order": order.name,
            }
        ).insert(ignore_permissions=True)

    _record_order_payment(order, order_data)
    _record_pos_payment(order, order_data)

    return api_response(
        data=order.as_dict(), message="Order created successfully."
    )


def _record_order_payment(order, order_data):
    """Record the payment for a just-created order when the client sent
    a ``payment_id`` (a PaaS Payment Gateway name — the key the customer
    checkout's ``OrderBodyData.toJson()`` has always included and this
    endpoint previously ignored, so wallet payments never debited and no
    Transaction was booked).

    Delegates to pay's ``create_order_transaction`` (the same endpoint
    the POS clients call after a sale) via the composed tenant module
    path — precedent: seller_order.py importing this SDK's settlement
    module — so every one of its guards applies unchanged: wallet debit
    with insufficient-balance refusal, Wallet History + legacy
    ``User.wallet_balance`` mirror sync, same order+gateway dedupe
    (returns ``{"duplicate": True}``), and the cross-gateway
    already-Paid guard.

    Behavior boundaries:
    - No ``payment_id`` in the payload: nothing changes — orders
      created without a payment method are untouched.
    - Guest session: recording is skipped with a server log (pay's
      endpoint refuses Guests; a guest order must still be creatable).
    - Pay's wallet module not composed into this tenant app (an
      unmigrated site): logged and skipped rather than crashing order
      creation. Only the IMPORT is guarded — a failure inside
      ``create_order_transaction`` itself (e.g. insufficient wallet
      balance) propagates, rolling the whole request transaction back
      so no unpaid order is silently minted.
    """
    payment_id = (order_data or {}).get("payment_id")
    if not payment_id:
        return
    if frappe.session.user == "Guest":
        frappe.log_error(
            title="create_order payment skipped",
            message=(
                "Order {0}: payment_id {1} sent on a Guest session; "
                "payment recording requires a logged-in user."
            ).format(order.name, payment_id),
        )
        return
    try:
        # Lazy composed-path import (pay and commerce SDKs compose into
        # the same tenant app); resolved per-call so commerce shells
        # without the pay wallet module keep creating orders.
        from {app_name}.wallet.tenant.api.payment import (
            create_order_transaction,
        )
    except ImportError:
        frappe.log_error(
            title="create_order payment skipped",
            message=(
                "Order {0}: payment_id {1} received but the pay wallet "
                "module is not composed into this app; no Transaction "
                "recorded."
            ).format(order.name, payment_id),
        )
        return
    create_order_transaction(order_id=order.name, payment_sys_id=payment_id)
    # A wallet payment marks the Order Paid through its own doc
    # instance; reload so the created-order response reflects it.
    order.reload()


def _record_pos_payment(order, order_data):
    """Record a seller (POS) till sale's payment state at creation: the
    credit / partly-paid contract behind the approved checkout frames
    (strip 11g-11i).

    Contract — honored ONLY for seller-origin orders (``_is_pos_order``)
    and only when no ``payment_id`` rode the payload (a gateway payment
    is ``_record_order_payment``'s job, unchanged):

    - ``payment_status: "Credit"`` (+ optional ``paid_now`` in
      ``[0, total)``): the sale completes on the customer's account. The
      paid-now portion collected at the till is recorded as a Paid
      ``Transaction`` row and stored on ``Order.pos_paid_amount``; the
      REMAINDER is the credit the existing machinery collects —
      ``auto_pay_credit_orders`` sweeps ``total - pos_paid_amount`` (in
      full, strict FIFO) and the credit-settled repayment passes the shop
      the same net amount. All-on-credit (``paid_now`` 0/absent) rides
      the merged credit machinery untouched.
    - ``paid_now`` >= total with no ``payment_status``: a fully paid till
      sale — the collected amount is recorded and the order flips Paid.
    - ``paid_now`` below total WITHOUT ``payment_status: "Credit"`` is
      refused: an underpaid sale must be an explicit credit sale.

    The ``order.save`` at the end re-runs the controller triggers, so a
    walk-in credit sale created Delivered+Credit credit-settles (the shop
    fronts the item commission) exactly like a driver conversion.
    """
    if order_data.get("payment_id"):
        return
    payment_status = str(order_data.get("payment_status") or "").strip()
    paid_now = order_data.get("paid_now")
    if not payment_status and paid_now is None:
        return
    if not _is_pos_order(order_data.get("shop")):
        frappe.throw(
            "payment_status / paid_now on create_order are for "
            "seller-origin (POS) orders only.",
            frappe.ValidationError,
        )
    if payment_status and payment_status.lower() != "credit":
        frappe.throw(
            "Invalid payment_status. A POS create may only supply "
            "'Credit'.",
            frappe.ValidationError,
        )

    total = float(order.total_price or 0)
    try:
        paid = float(paid_now or 0)
    except (TypeError, ValueError):
        frappe.throw("paid_now must be a number.", frappe.ValidationError)
    if paid < 0:
        frappe.throw(
            "paid_now cannot be negative.", frappe.ValidationError
        )
    paid = min(paid, total)
    is_credit = bool(payment_status)
    if not is_credit and paid + 0.005 < total:
        frappe.throw(
            "paid_now {0} does not cover the order total {1}; an "
            "underpaid sale must be created with payment_status "
            "'Credit'.".format(paid, total),
            frappe.ValidationError,
        )

    if paid > 0:
        # The till already holds this money (cash in the drawer / the
        # paying-now portion of the pay-link) — book the payment record
        # the way the settlement sweep does, against the Order.
        frappe.get_doc(
            {
                "doctype": "Transaction",
                "user": order.user,
                "payable_type": "Order",
                "payable_id": order.name,
                "amount": paid,
                "status": "Paid",
                "type": "model",
                "performed_at": frappe.utils.now_datetime(),
                "note": "POS till payment for Order {0} (collected at "
                "the till)".format(order.name),
            }
        ).insert(ignore_permissions=True)

    if is_credit:
        order.payment_status = "Credit"
        # Guarded like credit_settled: an unmigrated site simply keeps
        # pos_paid_amount off the doc and the sweep falls back to the
        # full total.
        try:
            has_pos_paid = frappe.get_meta("Order").has_field(
                "pos_paid_amount"
            )
        except Exception:
            has_pos_paid = True
        if has_pos_paid:
            order.pos_paid_amount = paid
    else:
        order.payment_status = "Paid"
    order.save(ignore_permissions=True)


def deposit_to_wallet(user, amount, note, commit=True):
    """
    Helper to add balance to user's wallet and log the transaction.

    ``commit`` exists for callers that are part of a larger all-or-
    nothing write and must not have this credit committed out from under
    a later failure (the seller's collected-in-person conversion is one:
    it credits the fee back, clears the driver and moves the order in
    one transaction). Defaults to the historical behaviour, so every
    existing caller is untouched.
    """
    if not amount or amount <= 0:
        return

    # 1. Fetch or Create Wallet
    wallet_name = frappe.db.get_value("Wallet", {"user": user}, "name")
    if not wallet_name:
        wallet = frappe.get_doc(
            {"doctype": "Wallet", "user": user, "balance": 0}
        ).insert(ignore_permissions=True)
    else:
        wallet = frappe.get_doc("Wallet", wallet_name)

    # 2. Update Balance
    wallet.balance += amount
    wallet.save(ignore_permissions=True)

    # 3. Create Transaction Audit Record
    frappe.get_doc(
        {
            "doctype": "Transaction",
            "user": user,
            "amount": amount,
            "status": "Paid",
            "type": "Refund",
            "note": note,
            "performed_at": frappe.utils.now_datetime(),
        }
    ).insert(ignore_permissions=True)

    if commit:
        frappe.db.commit()


@frappe.whitelist()
def list_orders(limit_start: int=0, limit_page_length: int=20,
                status: str=None, page: int=None) -> Any:
    """
    Retrieves a list of orders for the current user.

    status: optional Order status filter. The dart client sends lowercase
        values ("delivered", "accepted"); matched case-insensitively
        against the Order doctype's Select options where meta is
        available, otherwise filtered on the raw value.
    page: optional 1-based page number (the dart client's pagination
        scheme: {"page": N, "limit_page_length": 10}). When given it
        takes precedence over limit_start:
        limit_start = (page - 1) * limit_page_length.

    Both are optional; callers that omit them get the exact
    limit_start/limit_page_length behavior as before.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your orders.")

    filters = {"user": user}
    if status:
        normalized = str(status).strip()
        try:
            options = (frappe.get_meta("Order")
                       .get_field("status").options or "").split("\n")
            normalized = next(
                (option for option in options
                 if option.lower() == normalized.lower()), normalized)
        except Exception:
            pass  # no/odd meta: filter on the raw value
        filters["status"] = normalized

    if page is not None:
        try:
            per_page = int(limit_page_length)
        except (TypeError, ValueError):
            per_page = 20
        try:
            limit_start = (max(int(page), 1) - 1) * per_page
        except (TypeError, ValueError):
            pass  # malformed page: keep limit_start as passed

    orders = frappe.get_list(
        "Order",
        filters=filters,
        fields=["name", "shop", "total_price", "status", "creation",
                "location"],
        offset=limit_start,
        limit=limit_page_length,
        order_by="creation desc",
        ignore_permissions=True,
    )
    for row in orders:
        # location is fetched only to resolve the drop-off grid cell for
        # the optional weather_notice annotation; it is popped so the
        # list payload stays exactly as before (additive field only).
        _annotate_weather(row, location=row.pop("location", None))
    return api_response(data=orders)


@frappe.whitelist()
def get_order_details(order_id: str) -> Any:
    """
    Retrieves the details of a specific order.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to view your orders.")

    # Bypass permission check for retrieval
    original_user = frappe.session.user
    frappe.set_user("Administrator")
    try:
        order = frappe.get_doc("Order", order_id)
    finally:
        frappe.set_user(original_user)
    if order.user != user:
        frappe.throw(
            "You are not authorized to view this order.",
            frappe.PermissionError,
        )
    # as_dict() already carries Order.location; the annotation is additive
    # (weather_notice appears only when the drop-off cell has an active
    # heads-up) and fail-silent everywhere else.
    return api_response(data=_annotate_weather(order.as_dict()))


@frappe.whitelist()
def update_order_status(order_id: str, status: str) -> Any:
    """
    Updates the status of a specific order.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to update an order.")

    # Bypass permission check for retrieval
    original_user = frappe.session.user
    frappe.set_user("Administrator")
    try:
        order = frappe.get_doc("Order", order_id)
    finally:
        frappe.set_user(original_user)

    if order.user != user and "System Manager" not in frappe.get_roles(user):
        frappe.throw(
            "You are not authorized to update this order.",
            frappe.PermissionError,
        )

    valid_statuses = (
        frappe.get_meta("Order").get_field("status").options.split("\n")
    )
    if status not in valid_statuses:
        frappe.throw(f"Invalid status. Must be one of {', '.join(valid_statuses)}")

    previous_status = order.status
    order.status = status
    order.save(ignore_permissions=True)

    # Subtract stock when order is Accepted (and wasn't already)
    if status == "Accepted" and previous_status != "Accepted":
        for item in order.order_items:
            # Check if product tracks stock
            product_doc = frappe.get_doc("Product", item.product)
            if product_doc.track_stock:
                # Find the Stock record for this shop and product
                stock_name = frappe.db.get_value(
                    "Stock",
                    {"shop": order.shop, "product": item.product},
                    "name",
                )
                if stock_name:
                    stock_doc = frappe.get_doc("Stock", stock_name)
                    stock_doc.quantity -= item.quantity
                    stock_doc.save(ignore_permissions=True)
                else:
                    # Optional: Create stock record if missing? checking with user pref "stocks belong to sellers"
                    # For now, let's log or create if not exists
                    frappe.get_doc(
                        {
                            "doctype": "Stock",
                            "shop": order.shop,
                            "product": item.product,
                            "quantity": -item.quantity,  # Allow negative logic if started from 0
                            "price": item.price,  # Init price
                        }
                    ).insert(ignore_permissions=True)

    # Restore stock if order is Cancelled/Rejected from a status that deducted
    # stock
    if status in ["Cancelled", "Rejected"] and previous_status in [
        "Accepted",
        "Prepared",
        "Delivered",
    ]:  # Assuming these are downstream of Accepted
        for item in order.order_items:
            product_doc = frappe.get_doc("Product", item.product)
            if product_doc.track_stock:
                stock_name = frappe.db.get_value(
                    "Stock",
                    {"shop": order.shop, "product": item.product},
                    "name",
                )
                if stock_name:
                    stock_doc = frappe.get_doc("Stock", stock_name)
                    stock_doc.quantity += item.quantity
                    stock_doc.save(ignore_permissions=True)

    return api_response(
        data=order.as_dict(), message="Order status updated successfully."
    )


@frappe.whitelist()
def add_order_review(order_id: str, rating: float, comment: str=None) -> Any:
    """
    Adds a review for a specific order.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to leave a review.")

    # Bypass permission check for retrieval
    original_user = frappe.session.user
    frappe.set_user("Administrator")
    try:
        order = frappe.get_doc("Order", order_id)
    finally:
        frappe.set_user(original_user)

    if order.user != user:
        frappe.throw(
            "You can only review your own orders.", frappe.PermissionError
        )

    if order.status != "Delivered":
        frappe.throw("You can only review delivered orders.")

    if frappe.db.exists(
        "Review",
        {"reviewable_type": "Order", "reviewable_id": order_id, "user": user},
    ):
        frappe.throw("You have already reviewed this order.")

    review = frappe.get_doc(
        {
            "doctype": "Review",
            "reviewable_type": "Order",
            "reviewable_id": order_id,
            "user": user,
            "rating": rating,
            "comment": comment,
            "published": 1,
        }
    )
    review.insert(ignore_permissions=True)
    return api_response(
        data=review.as_dict(), message="Review added successfully."
    )


@frappe.whitelist()
def cancel_order(order_id: str) -> Any:
    """
    Cancels a specific order.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    if user == "Guest":
        frappe.throw("You must be logged in to cancel an order.")

    # Bypass permission check for retrieval
    original_user = frappe.session.user
    frappe.set_user("Administrator")
    try:
        order = frappe.get_doc("Order", order_id)
    finally:
        frappe.set_user(original_user)

    if order.user != user and "System Manager" not in frappe.get_roles(user):
        frappe.throw(
            "You are not authorized to cancel this order.",
            frappe.PermissionError,
        )

    if order.status != "New":
        frappe.throw(
            "You can only cancel orders that have not been accepted yet."
        )

    order.status = "Cancelled"
    # No stock restoration needed for "New" orders as stock wasn't deducted
    # yet.

    order.save(ignore_permissions=True)
    return api_response(
        data=order.as_dict(), message="Order cancelled successfully."
    )


@frappe.whitelist(allow_guest=True)
def get_order_statuses() -> Any:
    """
    Retrieves a list of active order statuses, formatted for frontend compatibility.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    statuses = frappe.get_list(
        "Order Status",
        filters={"is_active": 1},
        fields=["name", "status_name", "sort_order"],
        order_by="sort_order asc",
    )

    formatted_statuses = []
    for status in statuses:
        formatted_statuses.append(
            {
                "id": status.name,
                "name": status.status_name,
                "active": True,
                "sort": status.sort_order,
            }
        )

    return api_response(data=formatted_statuses)


@frappe.whitelist()
def get_calculate(cart_id: Any, address: Any=None, coupon_code: Any=None, tips: Any=0, delivery_type: Any='Delivery') -> Any:
    """
    The get_calculate function calculates the total cost of a shopping cart, taking into account various factors such as product prices, taxes, discounts, delivery fees, and service fees. 
    
    It accepts the following parameters: 
    - cart_id: the unique identifier of the shopping cart
    - address: the delivery address, which can be a string or a dictionary containing latitude and longitude coordinates
    - coupon_code: a discount coupon code to apply to the order
    - tips: the amount of tips to add to the order, defaulting to 0
    - delivery_type: the type of delivery, defaulting to 'Delivery'
    
    The function returns a dictionary containing the calculated totals, including the total tax, product price, shop tax, total price, discount, delivery fee, service fee, tips, and coupon price. 
    
    This function is used to provide an accurate estimate of the total cost of an order, considering various factors that may affect the final price.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    if isinstance(address, str) and address:
        try:
            address = json.loads(address)
        except Exception:
            address = None

    cart = frappe.get_doc("Cart", cart_id)
    shop = frappe.get_doc("Shop", cart.shop)

    # 1. Calculate Product Totals
    product_tax = 0
    product_total = 0
    subtotal_buffer = 0  # To track price protection for alternatives
    discount = 0
    calculated_products = []

    for item in cart.items:
        # Using 'Product' instead of 'Item' as per project conventions
        product_doc = frappe.get_doc("Product", item.item)

        item_price = product_doc.price or 0

        # Pay-Max Logic: Use alternative price if higher
        effective_price = item_price
        if item.alternative_product:
            alt_price = (
                frappe.db.get_value(
                    "Product", item.alternative_product, "price"
                )
                or 0
            )
            if alt_price > item_price:
                effective_price = alt_price
                subtotal_buffer += (alt_price - item_price) * (
                    item.quantity or 0
                )

        item_qty = item.quantity or 0
        item_tax = (effective_price * (product_doc.tax or 0) / 100) * item_qty
        item_discount = (
            effective_price * (item.discount_percentage or 0) / 100
        ) * item_qty

        item_total = (effective_price * item_qty) - item_discount + item_tax

        product_total += effective_price * item_qty
        product_tax += item_tax
        discount += item_discount

        calculated_products.append(
            {
                "id": product_doc.name,
                "price": effective_price,
                "original_price": item_price,
                "qty": item_qty,
                "tax": item_tax,
                "shop_tax": 0,  # Placeholder or specific shop tax per item
                "discount": item_discount,
                "price_without_tax": effective_price,
                "total_price": item_total,
                "is_buffered": effective_price > item_price,
            }
        )

    # 2. Calculate Delivery Fee
    delivery_fee = 0
    if delivery_type == "Delivery" and address:
        from math import radians, sin, cos, sqrt, atan2

        def haversine(lat1, lon1, lat2, lon2):
            R = 6371  # Radius of Earth in kilometers
            dLat = radians(lat2 - lat1)
            dLon = radians(lon2 - lon1)
            lat1 = radians(lat1)
            lat2 = radians(lat2)
            a = sin(dLat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dLon / 2) ** 2
            c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return R * c

        # Shop coordinates live in the location JSON field; the Shop
        # doctype has no latitude/longitude columns.
        from {app_name}.merchants.tenant.api.shop.shop import get_shop_coords

        shop_lat, shop_lon = get_shop_coords(shop)

        # The address arrives client-supplied (JSON string or dict) and
        # may carry string coordinates; coerce defensively — an
        # unparseable address means no distance fee, not a 500.
        addr_lat = addr_lon = None
        try:
            addr_lat = float(address.get("latitude"))
            addr_lon = float(address.get("longitude"))
        except (TypeError, ValueError, AttributeError):
            addr_lat = addr_lon = None

        if (
            shop_lat is not None
            and shop_lon is not None
            and addr_lat
            and addr_lon
        ):
            distance = haversine(
                shop_lat,
                shop_lon,
                addr_lat,
                addr_lon,
            )
            delivery_fee = (
                distance * shop.price_per_km if shop.price_per_km else 0
            )

    # 3. Calculate Shop Tax
    # Total tax on the whole order from the shop's tax setting
    shop_tax = (product_total - discount) * (shop.tax / 100) if shop.tax else 0

    # 4. Get Service Fee from Permission Settings
    paas_settings = frappe.get_single("Permission Settings")
    service_fee = paas_settings.service_fee or 0

    # 5. Apply Coupon
    coupon_price = 0
    if coupon_code:
        try:
            # Check for coupon linked to this shop or global
            coupon_doc = frappe.db.get_value(
                "Coupon",
                {"coupon_code": coupon_code, "shop": cart.shop},
                [
                    "name",
                    "coupon_type",
                    "discount_percentage",
                    "discount_amount",
                ],
                as_dict=True,
            )
            if coupon_doc:
                if coupon_doc.coupon_type == "Percentage":
                    coupon_price = (product_total - discount) * (
                        coupon_doc.discount_percentage / 100
                    )
                else:  # Fixed Amount
                    coupon_price = coupon_doc.discount_amount
        except Exception:
            pass

    # 6. Calculate Final Total
    order_total = (
        (product_total - discount)
        + delivery_fee
        + shop_tax
        + service_fee
        - coupon_price
        + float(tips)
    )

    # 7. 18+ (adults only) flags — additive keys for the checkout client.
    # requires_birth_date is true iff the cart holds an adult item AND the
    # session user has no birth_date on file (false when no adult items).
    cart_product_ids = [item.item for item in cart.items if item.item]
    contains_adult_items = bool(
        cart_product_ids
        and frappe.db.count(
            "Product", {"name": ["in", cart_product_ids], "is_adult": 1}
        )
    )
    requires_birth_date = False
    if contains_adult_items:
        session_user = frappe.session.user
        birth_date = (
            frappe.db.get_value("User", session_user, "birth_date")
            if session_user and session_user != "Guest"
            else None
        )
        requires_birth_date = not birth_date

    # Return in the format expected by GetCalculateModel
    return api_response(
        data={
            "total_tax": product_tax,
            "price": product_total,
            "total_shop_tax": shop_tax,
            "total_price": max(order_total, 0),
            "total_discount": discount + coupon_price,
            "delivery_fee": delivery_fee,
            "service_fee": service_fee,
            "tips": float(tips),
            "coupon_price": coupon_price,
            "subtotal_buffer": subtotal_buffer,
            "contains_adult_items": contains_adult_items,
            "requires_birth_date": requires_birth_date,
        }
    )
