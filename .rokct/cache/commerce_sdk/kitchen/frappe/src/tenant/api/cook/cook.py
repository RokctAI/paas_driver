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
from {app_name}.base.tenant.api.utils import _get_seller_shop

# The manager Kitchen screen speaks the fleet's legacy lowercase wire
# statuses; the Order doctype stores capitalized Select values. One map,
# both directions (the dish-line prep_status Select reuses the same
# vocabulary minus the courier states).
_WIRE_TO_DB_STATUS = {
    "new": "New",
    "accepted": "Accepted",
    "cooking": "Cooking",
    "ready": "Ready",
    "canceled": "Cancelled",
    "cancelled": "Cancelled",
    "delivered": "Delivered",
    "on_a_way": "Shipped",
}

# The statuses a kitchen cares about — the "All" filter of the manager
# Kitchen screen. New orders stay on the orders board until accepted;
# delivered/shipped orders have left the kitchen.
_KITCHEN_DB_STATUSES = ["Accepted", "Cooking", "Ready", "Cancelled"]


@frappe.whitelist()
def get_cook_orders(limit_start: int=0, limit_page_length: int=20) -> Any:
    """
    Retrieves a list of orders assigned to the current cook.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    if user == "Guest":
        frappe.throw(
            "You must be logged in to view your orders.",
            frappe.AuthenticationError,
        )

    orders = frappe.get_list(
        "Order",
        filters={"cook": user},
        fields=["name", "shop", "total_price", "status", "creation"],
        offset=limit_start,
        limit=limit_page_length,
        order_by="creation desc",
    )
    return orders


@frappe.whitelist()
def get_cook_order_report(from_date: str, to_date: str) -> Any:
    """
    Retrieves a report of orders for the current cook within a date range.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    if user == "Guest":
        frappe.throw(
            "You must be logged in to view your order report.",
            frappe.AuthenticationError,
        )

    orders = frappe.get_all(
        "Order",
        filters={"cook": user, "creation": ["between", [from_date, to_date]]},
        fields=["name", "shop", "total_price", "status", "creation"],
        order_by="creation desc",
    )
    return orders


@frappe.whitelist()
def get_kitchen_orders(limit_start: int=0, limit_page_length: int=20, status: str=None, search: str=None) -> Any:
    """
    The manager Kitchen screen's queue: the current seller shop's orders in
    the kitchen-relevant statuses, each carrying its dish lines (product
    title, quantity, per-line prep_status) plus the fields the approved
    kitchen cards render (delivery_type, cook-visible note, timestamps).

    ``get_cook_orders`` above stays untouched: it is assignee-scoped
    (cook == session user) and returns no dish lines, which cannot power
    the shop-wide manager queue. ``status`` takes the legacy lowercase wire
    value ('accepted'/'cooking'/'ready'/'canceled'); absent means all
    kitchen statuses. ``search`` narrows by order docname substring.

    Returns ``{"orders": [...], "counts": {...}, "total": n}`` — counts
    feed the filter chips, total the current filter's "view more" paging.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if status:
        db_status = _WIRE_TO_DB_STATUS.get(str(status).lower())
        if db_status is None or db_status not in _KITCHEN_DB_STATUSES:
            frappe.throw(
                "Invalid kitchen status. Must be one of: accepted, cooking, ready, canceled"
            )
        status_filter = db_status
    else:
        status_filter = ["in", _KITCHEN_DB_STATUSES]

    filters = {"shop": shop, "status": status_filter}
    if search:
        filters["name"] = ["like", f"%{search}%"]

    orders = frappe.get_list(
        "Order",
        filters=filters,
        fields=[
            "name", "status", "creation", "modified",
            "delivery_type", "note",
        ],
        offset=limit_start,
        limit=limit_page_length,
        order_by="creation desc",
    )

    # Dish lines ride along so the queue cards can show their preview and
    # the detail pane needs no second request. prep_status is meta-guarded
    # (get_seller_orders' pos_paid_amount precedent) so an un-migrated
    # site still answers.
    has_prep = False
    try:
        has_prep = frappe.get_meta("Order Item").has_field("prep_status")
    except Exception:
        pass  # no/odd meta: keep the guaranteed fields
    item_fields = ["name", "product", "quantity"]
    if has_prep:
        item_fields.append("prep_status")

    for order in orders:
        items = frappe.get_all(
            "Order Item",
            filters={"parent": order["name"], "parenttype": "Order"},
            fields=item_fields,
            order_by="idx",
        )
        for item in items:
            item["title"] = frappe.get_value(
                "Product", item["product"], "title"
            ) if item.get("product") else None
            if not has_prep:
                item["prep_status"] = None
        order["items"] = items

    counts = {"all": 0}
    for db_status in _KITCHEN_DB_STATUSES:
        count_filters = {"shop": shop, "status": db_status}
        if search:
            count_filters["name"] = ["like", f"%{search}%"]
        n = frappe.db.count("Order", count_filters)
        # Chips speak wire: Cancelled counts under the legacy 'canceled'.
        wire = db_status.lower() if db_status != "Cancelled" else "canceled"
        counts[wire] = n
        counts["all"] += n

    total = frappe.db.count("Order", filters)
    return {"orders": orders, "counts": counts, "total": total}


@frappe.whitelist()
def update_kitchen_dish_status(order_id: Any, item_id: Any, prep_status: Any) -> Any:
    """
    Sets one dish line's prep_status on an order of the current seller's
    shop (the manager Kitchen screen's tap-to-advance / double-tap-cancel
    dish flow). ``item_id`` is the Order Item child-row docname carried in
    ``get_kitchen_orders`` items; ``prep_status`` takes the lowercase wire
    value ('new'/'cooking'/'ready'/'canceled'). Order-level status stays
    untouched here — the client drives the order flow through
    update_seller_order_status, exactly like the POS kitchen did.
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

    db_status = _WIRE_TO_DB_STATUS.get(str(prep_status).lower())
    if db_status is None or db_status not in ["New", "Cooking", "Ready", "Cancelled"]:
        frappe.throw(
            "Invalid prep status. Must be one of: new, cooking, ready, canceled"
        )

    matched = None
    for item in order.order_items:
        if item.name == item_id:
            matched = item
            break
    if matched is None:
        frappe.throw("No such dish line on this order.")

    matched.prep_status = db_status
    order.save(ignore_permissions=True)
    return order.as_dict()
