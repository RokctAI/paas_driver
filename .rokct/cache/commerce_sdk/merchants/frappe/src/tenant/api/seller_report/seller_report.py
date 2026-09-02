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

# The legacy client's per-status tiles use its own status vocabulary; the
# Order doctype's Select options are New / Accepted / Shipped / Delivered /
# Cancelled / Paid / Failed. "Shipped" is the on-a-way leg; there is no
# distinct "Ready" state on this doctype, so that counter stays 0.
_STATUS_KEY_MAP = {
    "New": "total_new_count",
    "Accepted": "total_accepted_count",
    "Shipped": "total_on_a_way_count",
    "Delivered": "total_delivered_count",
    "Cancelled": "total_canceled_count",
}


def _order_window_filters(shop: Any, from_date: Any, to_date: Any) -> dict:
    filters = {"shop": shop}
    if from_date and to_date:
        filters["creation"] = ["between", [from_date, to_date]]
    return filters


# Profit report status vocabulary (approved revenue dashboard, section 36):
# DB Select values -> the wire keys of the ``status_counts`` block. ``Ready``
# has no wire key of its own in the contract — a ready order is still in the
# kitchen, so it counts under ``cooking``. ``Paid``/``Failed`` are payment
# outcomes, not order-flow states: they stay out of the split bar (but their
# orders still count in ``totals.orders``).
_PROFIT_STATUS_WIRE = {
    "New": "new",
    "Accepted": "accepted",
    "Cooking": "cooking",
    "Ready": "cooking",
    "Shipped": "on_a_way",
    "Delivered": "delivered",
    "Cancelled": "cancelled",
}


@frappe.whitelist()
def get_order_report(from_date: Any=None, to_date: Any=None, type: Any=None) -> Any:
    """
    Seller income statistics for a date window.

    Returns the aggregate ``StatisticsModel`` map the revenue client parses
    (see revenue_sdk ``docs/frappe-endpoint-contract.md``): earnings totals,
    per-status counters (unmerged), the last-order row, and a daily
    ``chart`` series of ``{time, total_price}`` points -- not a raw order
    list. Monetary aggregates and the chart are computed over Delivered
    orders; counters cover every order in the window. ``type`` (``day``) is
    accepted for legacy-client compatibility; the chart is always daily.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    if not from_date or not to_date:
        from_date = frappe.utils.add_months(frappe.utils.today(), -1)
        to_date = frappe.utils.today()

    user = frappe.session.user
    shop = _get_seller_shop(user)

    orders = frappe.get_all(
        "Order",
        filters=_order_window_filters(shop, from_date, to_date),
        fields=["name", "total_price", "commission_fee", "status", "creation"],
        order_by="creation desc",
    )

    flt = frappe.utils.flt
    today = frappe.utils.getdate(frappe.utils.today())

    status_counts = {}
    total_today_count = 0
    total_price = 0
    fm_total_price = 0
    chart_by_day = {}
    for order in orders:
        status_counts[order.status] = status_counts.get(order.status, 0) + 1
        if frappe.utils.getdate(order.creation) == today:
            total_today_count += 1
        if order.status == "Delivered":
            amount = flt(order.total_price)
            total_price += amount
            fm_total_price += amount - flt(order.commission_fee)
            day = str(frappe.utils.getdate(order.creation))
            chart_by_day[day] = chart_by_day.get(day, 0) + amount

    last_order_total_price = 0
    last_order_income = 0
    if orders:
        last = orders[0]  # newest first per order_by
        last_order_total_price = flt(last.total_price)
        last_order_income = flt(last.total_price) - flt(last.commission_fee)

    result = {
        "total_price": total_price,
        "fm_total_price": fm_total_price,
        "total_count": len(orders),
        "total_today_count": total_today_count,
        "total_ready_count": 0,
        "last_order_total_price": last_order_total_price,
        "last_order_income": last_order_income,
        "chart": [
            {"time": day, "total_price": chart_by_day[day]}
            for day in sorted(chart_by_day)
        ],
    }
    for status, key in _STATUS_KEY_MAP.items():
        result[key] = status_counts.get(status, 0)
    return result


@frappe.whitelist()
def get_order_report_paginate(
    from_date: Any=None,
    to_date: Any=None,
    page: Any=1,
    per_page: Any=None,
    limit_start: Any=None,
    limit_page_length: Any=None,
) -> Any:
    """
    Paginated per-order rows behind the income page's "more orders" list.

    Emits the legacy ``StatisticsOrder`` row shape (``id``, ``status``,
    ``firstname``, ``lastname``, ``active``, ``quantity``, ``price``,
    ``products``) under a ``data`` key, taking the client's ``page`` /
    ``per_page`` parameters (``limit_start`` / ``limit_page_length`` are
    kept as fallbacks for older callers). ``id`` is numeric only when the
    Order name is numeric -- the client field is typed int.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    cint = frappe.utils.cint
    flt = frappe.utils.flt

    user = frappe.session.user
    shop = _get_seller_shop(user)

    per_page = cint(per_page) or cint(limit_page_length) or 20
    offset = cint(limit_start) or (max(cint(page) or 1, 1) - 1) * per_page

    orders = frappe.get_all(
        "Order",
        filters=_order_window_filters(shop, from_date, to_date),
        fields=["name", "user", "total_price", "status", "creation"],
        offset=offset,
        limit=per_page,
        order_by="creation desc",
    )

    user_ids = list({o.user for o in orders if o.user})
    users = {}
    if user_ids:
        users = {
            u.name: u
            for u in frappe.get_all(
                "User",
                filters={"name": ["in", user_ids]},
                fields=["name", "first_name", "last_name"],
            )
        }

    order_names = [o.name for o in orders]
    items_by_order = {}
    product_titles = {}
    if order_names:
        items = frappe.get_all(
            "Order Item",
            filters={"parenttype": "Order", "parent": ["in", order_names]},
            fields=["parent", "product", "quantity"],
        )
        for item in items:
            items_by_order.setdefault(item.parent, []).append(item)
        product_ids = list({i.product for i in items if i.product})
        if product_ids:
            product_titles = {
                p.name: p.title
                for p in frappe.get_all(
                    "Product",
                    filters={"name": ["in", product_ids]},
                    fields=["name", "title"],
                )
            }

    rows = []
    for order in orders:
        buyer = users.get(order.user)
        order_items = items_by_order.get(order.name, [])
        rows.append(
            {
                "id": (
                    cint(order.name)
                    if str(order.name).isdigit()
                    else None
                ),
                "status": order.status,
                "firstname": buyer.first_name if buyer else None,
                "lastname": buyer.last_name if buyer else None,
                "active": 1,
                "quantity": sum(cint(i.quantity) for i in order_items),
                "price": flt(order.total_price),
                "products": [
                    product_titles.get(i.product) or i.product
                    for i in order_items
                    if i.product
                ],
            }
        )

    return {"data": rows}


@frappe.whitelist()
def get_seller_profit_report(from_date: Any=None, to_date: Any=None) -> Any:
    """
    Shop-scoped profitability aggregates over Order / Order Item — the one
    backend addition behind the approved revenue dashboard (section 36,
    Ray's 2026-08-29 14:51Z profitability requirement).

    Profit is computed from the ``cost_price`` SNAPSHOT frozen onto every
    order line at sale (order.py copies Product.cost into
    ``order_items.cost_price`` when the order is created), never from the
    product's current cost — changing a cost later never rewrites old
    orders. Per line, where ``cost_price > 0``::

        profit = (price - cost_price) * quantity

    Lines with ``cost_price <= 0`` (cost never set, or the order predates
    the cost field — ``or 0`` on the create path stores unset as 0) are the
    UNKNOWN BUCKET: their revenue is excluded from profit and from the
    margin denominator, and is NEVER counted as pure profit. ``margin_pct``
    divides profit by COSTED revenue only, as a percentage.

    An order is "costed" when it has at least one line and every line
    carries a positive ``cost_price``; every other order in the window
    lands in ``unknown_bucket.orders``, so
    ``totals.orders_costed + unknown_bucket.orders == totals.orders``.

    ``series`` buckets revenue/profit per day (ascending); when
    ``from_date == to_date`` it buckets per hour of that day instead.
    ``products`` aggregates per product sold in the window, sorted costed
    rows first by profit descending, then cost-missing rows by revenue;
    ``price``/``cost`` on each row are the product's CURRENT values (for
    the Price/Cost/Margin strip), while ``profit`` stays snapshot-based.

    ``status_counts`` uses the wire vocabulary of the split bar
    (new/accepted/cooking/on_a_way/delivered/cancelled); see
    ``_PROFIT_STATUS_WIRE`` for the mapping. The previous-period deltas the
    dashboard shows come from the client calling this endpoint again for
    the shifted window. ``get_order_report`` / ``get_order_report_paginate``
    above stay untouched (backward-compat rule) — the payout strip still
    reads ``get_order_report``.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    if not from_date or not to_date:
        from_date = frappe.utils.add_months(frappe.utils.today(), -1)
        to_date = frappe.utils.today()

    user = frappe.session.user
    shop = _get_seller_shop(user)

    flt = frappe.utils.flt
    cint = frappe.utils.cint

    orders = frappe.get_all(
        "Order",
        filters=_order_window_filters(shop, from_date, to_date),
        fields=["name", "status", "creation"],
        order_by="creation desc",
    )

    status_counts = {
        key: 0 for key in
        ["new", "accepted", "cooking", "on_a_way", "delivered", "cancelled"]
    }
    for order in orders:
        wire = _PROFIT_STATUS_WIRE.get(order.status)
        if wire:
            status_counts[wire] += 1

    order_names = [o.name for o in orders]
    items = []
    if order_names:
        items = frappe.get_all(
            "Order Item",
            filters={"parenttype": "Order", "parent": ["in", order_names]},
            fields=["parent", "product", "quantity", "price", "cost_price"],
        )

    hourly = bool(from_date) and str(from_date) == str(to_date)
    order_day = {}
    for order in orders:
        if hourly:
            # Hour bucket of the single requested day.
            creation = str(order.creation)
            hour = creation[11:13] if len(creation) >= 13 else "00"
            order_day[order.name] = f"{hour}:00"
        else:
            order_day[order.name] = str(frappe.utils.getdate(order.creation))

    revenue = 0.0
    profit = 0.0
    costed_revenue = 0.0
    excluded_revenue = 0.0
    series = {}
    per_product = {}
    # Orders holding >= 1 uncosted line; a no-line order is never costed
    # either, so "costed" is derived at the end from the orders that had
    # lines and none of them uncosted.
    orders_with_lines = set()
    orders_with_uncosted_line = set()

    for item in items:
        qty = cint(item.quantity)
        price = flt(item.price)
        cost = flt(item.cost_price)
        line_revenue = price * qty
        revenue += line_revenue
        orders_with_lines.add(item.parent)

        day = order_day.get(item.parent)
        bucket = series.setdefault(day, {"revenue": 0.0, "profit": 0.0})
        bucket["revenue"] += line_revenue

        row = per_product.setdefault(
            item.product,
            {"sold": 0, "revenue": 0.0, "profit": 0.0, "costed_revenue": 0.0},
        )
        row["sold"] += qty
        row["revenue"] += line_revenue

        if cost > 0:
            line_profit = (price - cost) * qty
            profit += line_profit
            costed_revenue += line_revenue
            bucket["profit"] += line_profit
            row["profit"] += line_profit
            row["costed_revenue"] += line_revenue
        else:
            excluded_revenue += line_revenue
            orders_with_uncosted_line.add(item.parent)

    orders_costed = len(
        [o for o in orders_with_lines if o not in orders_with_uncosted_line]
    )
    total_orders = len(orders)
    unknown_orders = total_orders - orders_costed

    product_meta = {}
    if per_product:
        product_meta = {
            p.name: p
            for p in frappe.get_all(
                "Product",
                filters={"name": ["in", list(per_product)]},
                fields=["name", "title", "price", "cost"],
            )
        }

    products = []
    for product_id, row in per_product.items():
        meta = product_meta.get(product_id)
        current_cost = flt(meta.cost) if meta else 0.0
        cost_missing = current_cost <= 0
        margin_pct = (
            row["profit"] / row["costed_revenue"] * 100.0
            if row["costed_revenue"] > 0
            else 0.0
        )
        products.append(
            {
                "product": product_id,
                "name": (meta.title if meta else None) or product_id,
                "sold": row["sold"],
                "revenue": row["revenue"],
                "price": flt(meta.price) if meta else 0.0,
                "cost": current_cost,
                "profit": row["profit"],
                "margin_pct": margin_pct,
                "cost_missing": cost_missing,
            }
        )
    # Costed rows first by profit desc; the cost-missing tail by revenue —
    # the honest "these could be earning" ordering of the approved list.
    products.sort(
        key=lambda p: (
            p["cost_missing"],
            -p["profit"] if not p["cost_missing"] else -p["revenue"],
        )
    )

    return {
        "totals": {
            "revenue": revenue,
            "profit": profit,
            "costed_revenue": costed_revenue,
            "margin_pct": (
                profit / costed_revenue * 100.0 if costed_revenue > 0 else 0.0
            ),
            "orders": total_orders,
            "orders_costed": orders_costed,
            "avg_order": revenue / total_orders if total_orders else 0.0,
        },
        "unknown_bucket": {
            "orders": unknown_orders,
            "revenue_excluded": excluded_revenue,
        },
        "series": [
            {"date": day, "revenue": series[day]["revenue"],
             "profit": series[day]["profit"]}
            for day in sorted(series, key=lambda d: (d is None, d))
        ],
        "products": products,
        "status_counts": status_counts,
    }
