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
from {app_name}.base.tenant.api.utils import _get_seller_shop


@frappe.whitelist()
def get_seller_orders(limit_start: int=0, limit_page_length: int=20, status: str=None, from_date: str=None, to_date: str=None, order_user: str=None, payment_status: str=None) -> Any:
    """
    Retrieves a list of orders for the current seller's shop, with optional filters.

    Additive filters for the POS checkout's customer credit surface
    (approved strip 11g, chip 306 — "owes" is the sum of the customer's
    open Credit orders): ``order_user`` narrows to one customer and
    ``payment_status`` to a payment state ("Credit" for the outstanding
    chip). The returned rows additively carry ``total_price``,
    ``payment_status`` and — where the site is migrated for the POS
    partly-paid contract — ``pos_paid_amount``, so the client can sum
    ``total_price - pos_paid_amount`` per open Credit order. Plain calls
    keep the exact legacy behavior and row shape (plus the additive
    fields).
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    filters = {"shop": shop}
    if status:
        filters["status"] = status
    if from_date and to_date:
        filters["creation"] = ["between", [from_date, to_date]]
    if order_user:
        filters["user"] = order_user
    if payment_status:
        filters["payment_status"] = payment_status

    fields = [
        "name", "user", "grand_total", "status", "creation",
        "total_price", "payment_status",
        # The board card reads the order TYPE off the row (its type chip
        # renders `delivery_type` as a translation key) and, for an order
        # collected in person, has to be able to say at a glance whether
        # the fee came back - the struck fee and the dropped total are
        # the visible proof (design strip section 43, chips 810/820/821).
        "delivery_type", "delivery_fee",
    ]
    try:
        meta = frappe.get_meta("Order")
        if meta.has_field("pos_paid_amount"):
            fields.append("pos_paid_amount")
        for optional in ("collected_in_person", "collect_fee_refunded"):
            if meta.has_field(optional):
                fields.append(optional)
    except Exception:
        pass  # no/odd meta: keep the guaranteed fields

    orders = frappe.get_list(
        "Order",
        filters=filters,
        fields=fields,
        offset=limit_start,
        limit=limit_page_length,
        order_by="creation desc",
    )
    return orders


@frappe.whitelist()
def get_seller_order_details(order_id: Any) -> Any:
    """
    Retrieves full details of a specific order.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    order = frappe.get_doc("Order", order_id)

    if order.shop != shop:
        frappe.throw(
            "You are not authorized to view this order.",
            frappe.PermissionError,
        )

    row = order.as_dict()
    # Additive: the assigned driver's readable name. `deliveryman` is a
    # Link to User (an id), and the seller detail has to be able to SAY
    # who is on the order - "Thabo Dlamini", not an email - before the
    # seller decides whether to hand the goods over the counter (design
    # strip section 43, chip 812). Absent when nobody is assigned.
    if row.get("deliveryman"):
        row["deliveryman_name"] = (
            frappe.db.get_value("User", row["deliveryman"], "full_name")
            or row["deliveryman"]
        )
    return row


@frappe.whitelist()
def update_seller_order_status(order_id: Any, status: Any) -> Any:
    """
    Updates the status of an order.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    order = frappe.get_doc("Order", order_id)

    if order.shop != shop:
        frappe.throw(
            "You are not authorized to update this order.",
            frappe.PermissionError,
        )

    # The manager clients (orders board, Kitchen screen) speak the fleet's
    # legacy lowercase wire statuses ('new', 'accepted', 'cooking', 'ready',
    # 'on_a_way', 'delivered', 'canceled'); the Order doctype stores
    # capitalized Select values. Accept both additively: exact capitalized
    # inputs behave exactly as before, wire values map onto them. 'Cooking'
    # joins the valid set — the board's cooking column and the kitchen's
    # "Start cooking" are real states of the Order status Select now.
    wire_to_db = {
        "new": "New",
        "accepted": "Accepted",
        "cooking": "Cooking",
        "ready": "Ready",
        "on_a_way": "Shipped",
        "delivered": "Delivered",
        "canceled": "Cancelled",
        "cancelled": "Cancelled",
        "paid": "Paid",
        "failed": "Failed",
    }
    valid_statuses = [
        "New",
        "Accepted",
        "Cooking",
        "Ready",
        "Shipped",
        "Delivered",
        "Cancelled",
        "Paid",
        "Failed",
    ]
    if status not in valid_statuses:
        status = wire_to_db.get(str(status).lower())
    if status not in valid_statuses:
        frappe.throw(f"Invalid status. Must be one of: {', '.join(valid_statuses)}")

    order.status = status
    order.save(ignore_permissions=True)
    return order.as_dict()


def _is_delivery_type(value: Any) -> bool:
    """`delivery_type` is a free Data field the fleet writes in both
    cases ("Delivery" from the customer checkout, 'delivery' from the
    till), so it is compared case-insensitively - the same reading the
    Order controller's auto-complete rule takes."""
    return str(value or "").strip().lower() == "delivery"


def _pickup_like(value: Any) -> str:
    """The Pickup spelling to write, in the case the order already used.

    Nothing normalizes `delivery_type` and both spellings are live on
    real rows; the manager board renders the value as a TRANSLATION KEY
    ('delivery' / 'pickup' are store keys), so rewriting a lowercase
    'delivery' as a capitalized "Pickup" would silently cost that card
    its translated label. Mirror the case instead of imposing one.
    """
    text = str(value or "").strip()
    return "pickup" if text and text == text.lower() else "Pickup"


@frappe.whitelist()
def convert_delivery_to_collected(order_id: Any) -> Any:
    """The customer turned up and collected a DELIVERY order in person.

    ONE endpoint, atomic over every write, because a client-driven
    sequence that fails half way leaves an order that is half converted -
    a Pickup order still carrying a driver, or a driver stood down on an
    order that never converted. Any throw below rolls the whole request
    back.

    Ray's policy, unbent: the goods are NEVER withheld and never
    forfeited, whatever happens to the money.

    * No driver had been dispatched -> the delivery fee goes back to the
      customer's wallet (`deposit_to_wallet`, which writes the Transaction
      audit row) and `delivery_fee` is zeroed, so the order's total drops
      by the fee.
    * A driver HAD been dispatched -> he still drove for it, so the fee is
      kept and paid to HIM as a callout (`settle_delivery_callout`), the
      order keeps its fee and its total, and his task disappears from the
      driver app the moment `deliveryman` is cleared - every driver-side
      query is filtered on that one field (zones
      `driver_order.get_driver_orders_paginate` / `fetch_current_order`,
      delivery `get_deliveryman_orders`), and no separate task record
      exists to go stale.

    THE ORDER OF THE WRITES IS THE POINT. The Order controller settles on
    every save once the order is Delivered + Paid, and `settle_order`
    credits the deliveryman the FULL `delivery_fee` while he is still
    assigned. So the assignment is cleared and the callout paid in the
    FIRST save, with the order still short of Delivered; only the second
    save moves it to Delivered, by which time it carries no driver and
    the settlement pays him nothing. Reverse the two and he is paid
    twice - once by the settlement, once by the callout.

    Idempotent: a second call on an already-converted order moves no
    money and returns the same envelope with `already_converted` true.
    That is what makes the till's offline path safe - the hand-over
    happens immediately and the conversion is replayed on reconnect.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    order = frappe.get_doc("Order", order_id)

    if order.shop != shop:
        frappe.throw(
            "You are not authorized to update this order.",
            frappe.PermissionError,
        )

    if order.get("collected_in_person"):
        return _collected_envelope(order, already=True)

    if not _is_delivery_type(order.get("delivery_type")):
        frappe.throw(
            "Order {0} is not a delivery order, so there is nothing to "
            "convert.".format(order.name),
            frappe.ValidationError,
        )

    if order.status == "Cancelled":
        frappe.throw(
            "Order {0} is cancelled.".format(order.name),
            frappe.ValidationError,
        )
    if order.status == "Delivered":
        frappe.throw(
            "Order {0} is already delivered.".format(order.name),
            frappe.ValidationError,
        )

    deliveryman = order.get("deliveryman")
    delivery_fee = float(order.get("delivery_fee") or 0)

    # ---- writes phase 1: money and assignment, BEFORE Delivered -------
    refunded = 0.0
    if delivery_fee <= 0:
        outcome = "none"
    elif deliveryman:
        # Lazy composed-path import, the same pattern
        # update_seller_order_refund uses for apply_refund_clawback.
        from {app_name}.orders.tenant.api.order.settlement import (
            settle_delivery_callout,
        )

        settle_delivery_callout(order)
        outcome = "kept"
    else:
        from {app_name}.orders.tenant.api.order.order import (
            deposit_to_wallet,
        )

        # commit=False: this credit is part of the conversion, not a
        # transaction of its own - a failure below must take it with it.
        deposit_to_wallet(
            order.user,
            delivery_fee,
            "Delivery fee returned for Order {0}: collected in person, "
            "no driver had been dispatched".format(order.name),
            commit=False,
        )
        refunded = delivery_fee
        order.delivery_fee = 0
        outcome = "refunded"

    order.deliveryman = None
    order.delivery_type = _pickup_like(order.get("delivery_type"))
    order.collected_in_person = 1
    order.collect_fee_refunded = refunded
    # Still short of Delivered on purpose: this save must not be able to
    # settle. `calculate_totals` runs in before_save, so zeroing the fee
    # above is what drops the total - the fee-kept branch leaves both
    # alone and the total is unchanged.
    order.save(ignore_permissions=True)

    # ---- writes phase 2: the hand-over itself -------------------------
    # Safe now: the order carries no deliveryman, so the controller's
    # settlement credits the shop and nobody else.
    order.status = "Delivered"
    order.save(ignore_permissions=True)

    return _collected_envelope(order, already=False, outcome=outcome,
                               refunded=refunded, driver=deliveryman,
                               fee=delivery_fee)


def _collected_envelope(order, already, outcome=None, refunded=None,
                        driver=None, fee=None):
    """The one response shape both the fresh conversion and the replay of
    an already-converted order return, so the till never has to branch on
    which of the two it got."""
    if outcome is None:
        stored = float(order.get("collect_fee_refunded") or 0)
        if stored > 0:
            outcome = "refunded"
        elif float(order.get("delivery_fee") or 0) > 0:
            outcome = "kept"
        else:
            outcome = "none"
    if refunded is None:
        refunded = float(order.get("collect_fee_refunded") or 0)
    if fee is None:
        fee = float(order.get("delivery_fee") or 0) + refunded
    total = float(order.get("total_price") or 0)
    return {
        "order": order.as_dict(),
        "converted": True,
        "already_converted": bool(already),
        # "kept" IS "a driver was on it" - the fee is only ever kept to
        # cover a callout - so a replay can answer this too, long after
        # `deliveryman` was cleared.
        "driver_was_assigned": bool(driver) or outcome == "kept",
        "unassigned_deliveryman": driver,
        "delivery_type": order.get("delivery_type"),
        "delivery_fee": fee,
        "fee_outcome": outcome,
        "refunded_to_wallet": refunded,
        "total_price": total,
        "total_price_before": total + refunded,
    }


@frappe.whitelist()
def get_seller_order_refunds(limit_start: int=0, limit_page_length: int=20) -> Any:
    """
    Retrieves a list of order refunds for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    orders = frappe.get_all("Order", filters={"shop": shop}, pluck="name")

    if not orders:
        return []

    refunds = frappe.get_list(
        "Order Refund",
        filters={"order": ["in", orders]},
        fields=["name", "order", "status", "cause", "answer"],
        offset=limit_start,
        limit=limit_page_length,
        order_by="creation desc",
    )
    return refunds


@frappe.whitelist()
def update_seller_order_refund(refund_name: Any, status: Any, answer: Any=None) -> Any:
    """
    Updates the status and answer of an order refund.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    refund = frappe.get_doc("Order Refund", refund_name)
    order = frappe.get_doc("Order", refund.order)

    if order.shop != shop:
        frappe.throw(
            "You are not authorized to update this refund request.",
            frappe.PermissionError,
        )

    if status not in ["Accepted", "Canceled"]:
        frappe.throw("Invalid status. Must be 'Accepted' or 'Canceled'.")

    refund.status = status
    if answer:
        refund.answer = answer

    refund.save(ignore_permissions=True)

    if status == "Accepted":
        # An approved refund moves real money: buyer credited with what
        # was actually collected, shop clawed back net of a proportional
        # commission reversal. Idempotent (clawback_settled flag on the
        # Order Refund), so re-approving cannot double-move; any throw
        # rolls the status flip back together with the wallet writes.
        # Lazy composed-path import, same pattern as api/order/order.py
        # importing merchants' get_shop_coords.
        from {app_name}.orders.tenant.api.order.settlement import (
            apply_refund_clawback,
        )

        apply_refund_clawback(refund)
        refund.reload()

    return refund.as_dict()


@frappe.whitelist()
def get_seller_reviews(limit_start: int=0, limit_page_length: int=20) -> Any:
    """
    Retrieves a list of reviews for products in the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    products = frappe.get_all("Item", filters={"shop": shop}, pluck="name")

    if not products:
        return []

    reviews = frappe.get_list(
        "Review",
        filters={"reviewable_id": ["in", products], "reviewable_type": "Item"},
        fields=[
            "name",
            "user",
            "rating",
            "comment",
            "creation",
            "reviewable_id",
        ],
        offset=limit_start,
        limit=limit_page_length,
        order_by="creation desc",
    )
    return reviews
