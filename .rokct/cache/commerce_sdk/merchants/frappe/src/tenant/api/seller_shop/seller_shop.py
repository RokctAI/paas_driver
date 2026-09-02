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
def get_shop() -> Any:
    """
    Retrieves the current seller's shop details.

    Field mapping follows the legacy client contract (``ShopData.fromJson``
    in the core base SDK): ``location`` must be a ``{latitude, longitude}``
    map or null -- never the raw Geolocation GeoJSON string stored on the
    doctype, which the client's ``Location.fromJson`` cannot parse.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    from {app_name}.merchants.tenant.api.shop.shop import get_shop_coords

    user = frappe.session.user
    shop_id = _get_seller_shop(user)

    shop = frappe.get_doc("Shop", shop_id)

    # Shop.location is a Geolocation field: a GeoJSON JSON *string* (or a
    # legacy flat lat/long object). Emit the parsed coordinate map the
    # client expects, or null when there is nothing parseable.
    lat, lon = get_shop_coords(shop)
    location = (
        {"latitude": lat, "longitude": lon}
        if lat is not None and lon is not None
        else None
    )

    # Shop reviews are polymorphic rows on the Review doctype
    # (reviewable_type/reviewable_id). Tolerate tenants without it.
    rating_avg = 0
    reviews_count = 0
    try:
        review_stats = frappe.get_all(
            "Review",
            filters={
                "reviewable_type": "Shop",
                "reviewable_id": shop_id,
                "published": 1,
            },
            fields=[
                "avg(rating) as rating_avg",
                "count(name) as reviews_count",
            ],
        )
        if review_stats:
            rating_avg = review_stats[0].get("rating_avg") or 0
            reviews_count = review_stats[0].get("reviews_count") or 0
    except Exception:
        pass

    return {
        "id": shop.name,
        "uuid": shop.uuid,
        "slug": shop.slug,
        "user_id": shop.user,
        "tax": shop.tax,
        "service_fee": shop.service_fee,
        "percentage": shop.percentage,
        "phone": shop.phone,
        "open": bool(shop.open),
        "visibility": bool(shop.visibility),
        "verify": bool(shop.verify),
        "logo_img": shop.logo,
        "background_img": shop.cover_photo,
        "min_amount": shop.min_amount,
        "price": shop.price,
        "price_per_km": shop.price_per_km,
        "status": shop.status,
        "delivery_time": {
            "type": shop.delivery_time_type,
            "from": shop.delivery_time_from,
            "to": shop.delivery_time_to,
        },
        "location": location,
        "title": shop.name,
        "address": shop.address,
        # The Shop doctype defines no `description` field; keep the key for
        # legacy clients but never crash when the column is absent.
        "description": shop.get("description"),
        "rating_avg": rating_avg,
        "reviews_count": reviews_count,
    }


@frappe.whitelist()
def update_shop(shop_data: Any) -> Any:
    """
    Updates the current seller's shop details.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop_id = _get_seller_shop(user)

    if isinstance(shop_data, str):
        shop_data = json.loads(shop_data)

    shop = frappe.get_doc("Shop", shop_id)

    # Update allowed fields
    allowed_fields = [
        "phone",
        "address",
        "location",
        "min_amount",
        "tax",
        "delivery_time_type",
        "delivery_time_from",
        "delivery_time_to",
        "open",
        "logo",
        "cover_photo",
        "description",
    ]

    for field in allowed_fields:
        if field in shop_data:
            shop.set(field, shop_data[field])

    # Handle specific mapping if needed (e.g. logo_img -> logo)
    if "logo_img" in shop_data:
        shop.logo = shop_data["logo_img"]
    if "background_img" in shop_data:
        shop.cover_photo = shop_data["background_img"]
    if "title" in shop_data:
        shop.shop_name = shop_data["title"]  # Assuming shop_name is the field

    shop.save(ignore_permissions=True)
    return shop.as_dict()


@frappe.whitelist()
def set_working_status(status: Any) -> Any:
    """
    Updates the shop's open status.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop_id = _get_seller_shop(user)

    shop = frappe.get_doc("Shop", shop_id)

    # status can be boolean or string "true"/"false" or 0/1
    if isinstance(status, str):
        if status.lower() == "true":
            status = 1
        elif status.lower() == "false":
            status = 0
        else:
            status = int(status)

    shop.open = 1 if status else 0
    shop.save(ignore_permissions=True)

    return shop.open


# --- ALIASES FOR FLUTTER ENDPOINTS ---


@frappe.whitelist()
def set_shop_working_status(status: Any=None) -> Any:
    """
    Set shop working status API endpoint.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return set_working_status(status)


# ---------------------------------------------------------------------------
# QUICK FLOW (design strip section 42) — the three shop switches that let the
# till run itself between customers, read and written as one surface.
#
#   (a) auto_accept_orders  -> `Shop.auto_approve_orders`, a field that ALREADY
#       EXISTS and is already honoured by `create_order` (orders' order.py:
#       `paas_settings.auto_approve_orders and shop.auto_approve_orders` ->
#       initial status "Accepted"). Nothing here changes that behaviour; the
#       surface only exposes the real field, plus the platform half of the gate
#       (`Permission Settings.auto_approve_orders`) READ-ONLY so the seller can
#       see why their switch may not be biting yet.
#   (b) auto_complete_at_ready -> a NEW Shop field, honoured by the Order
#       controller (orders' doctype/order/order.py `complete_at_ready_if_due`).
#   (c) keypad_autodial + digit_presets -> a NEW per-shop digit->product map
#       (child table "Shop Digit Preset"). The till interprets a digit press
#       against it while its ticket is empty; the keypad component itself is
#       untouched.
#
# The preset rows come back with their product already serialized in the
# fleet's product-payload shape (`id` / `translation.title` / `stocks[]`), so
# the till can drop one straight on the ticket with no second round trip —
# a digit press must never wait on the network.
# ---------------------------------------------------------------------------

_QUICK_FLOW_DIGITS = ("1", "2", "3", "4", "5", "6", "7", "8", "9")


def _platform_auto_approve() -> bool:
    """The platform half of the auto-accept gate, read-only for the seller.

    `Shop.auto_approve_orders` only bites when the admin's
    `Permission Settings.auto_approve_orders` is on too (the doctype's own
    description says so) — tolerate a tenant without the single.
    """
    try:
        return bool(
            frappe.db.get_single_value(
                "Permission Settings", "auto_approve_orders"
            )
        )
    except Exception:
        return False


def _preset_product_payload(product_id: Any) -> Optional[dict]:
    """Serialize one preset's product the way the client's `ProductData`
    reads it (the till builds a cart line from this and nothing else)."""
    if not product_id or not frappe.db.exists("Product", product_id):
        return None
    product = frappe.get_doc("Product", product_id)
    stocks = frappe.get_all(
        "Stock",
        filters={"product": product.name},
        fields=["name", "price", "quantity"],
        order_by="creation asc",
        limit_page_length=1,
    )
    return {
        "id": product.name,
        "shop_id": product.get("shop"),
        "img": product.get("image"),
        "translation": {"title": product.get("title")},
        "stocks": [
            {
                "id": row.get("name"),
                "countable_id": product.name,
                "price": row.get("price") or product.get("price") or 0,
                "quantity": row.get("quantity") or 0,
            }
            for row in stocks
        ]
        or [
            {
                "id": product.name,
                "countable_id": product.name,
                "price": product.get("price") or 0,
                "quantity": 0,
            }
        ],
    }


def _quick_flow_payload(shop: Any) -> dict:
    presets = []
    for row in shop.get("digit_presets") or []:
        product = _preset_product_payload(row.get("product"))
        if product is None:
            # A preset whose product was deleted is simply not served — the
            # digit falls back to inert, which is the unset-slot behaviour
            # the till already draws (chip 805).
            continue
        presets.append({"digit": str(row.get("digit")), "product": product})
    return {
        "shop_id": shop.name,
        "shop_name": shop.get("shop_name") or shop.name,
        "auto_accept_orders": bool(shop.get("auto_approve_orders")),
        "platform_auto_approve": _platform_auto_approve(),
        "auto_complete_at_ready": bool(shop.get("auto_complete_at_ready")),
        "keypad_autodial": bool(shop.get("keypad_autodial")),
        "digit_presets": presets,
    }


@frappe.whitelist()
def get_quick_flow_settings() -> Any:
    """Reads the calling seller's Quick flow settings (section 42)."""
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop_id = _get_seller_shop(user)
    shop = frappe.get_doc("Shop", shop_id)
    return _quick_flow_payload(shop)


@frappe.whitelist()
def update_quick_flow_settings(settings: Any) -> Any:
    """Writes the calling seller's Quick flow settings (section 42).

    Every key is optional — the surface saves one switch at a time. When
    ``digit_presets`` is supplied it REPLACES the whole map (the client owns
    the 1-9 grid as a unit), which is what keeps a digit from ever holding
    two products.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop_id = _get_seller_shop(user)

    if isinstance(settings, str):
        settings = json.loads(settings)
    if not isinstance(settings, dict):
        frappe.throw("settings must be an object.")

    shop = frappe.get_doc("Shop", shop_id)

    for key, field in (
        ("auto_accept_orders", "auto_approve_orders"),
        ("auto_complete_at_ready", "auto_complete_at_ready"),
        ("keypad_autodial", "keypad_autodial"),
    ):
        if key in settings:
            shop.set(field, 1 if settings.get(key) else 0)

    if "digit_presets" in settings:
        rows = settings.get("digit_presets") or []
        if not isinstance(rows, list):
            frappe.throw("digit_presets must be a list.")
        seen = set()
        rebuilt = []
        for row in rows:
            digit = str((row or {}).get("digit") or "").strip()
            product = (row or {}).get("product")
            if isinstance(product, dict):
                product = product.get("id")
            if digit not in _QUICK_FLOW_DIGITS:
                frappe.throw(
                    "Preset digit must be one of {0}.".format(
                        ", ".join(_QUICK_FLOW_DIGITS)
                    )
                )
            if digit in seen:
                frappe.throw("Digit {0} is mapped twice.".format(digit))
            if not product or not frappe.db.exists("Product", product):
                frappe.throw("Preset product for digit {0} does not exist.".format(digit))
            if frappe.db.get_value("Product", product, "shop") != shop_id:
                frappe.throw(
                    "Preset product for digit {0} belongs to another shop.".format(digit)
                )
            seen.add(digit)
            rebuilt.append({"digit": digit, "product": product})
        shop.set("digit_presets", [])
        for row in rebuilt:
            shop.append("digit_presets", row)

    shop.save(ignore_permissions=True)
    return _quick_flow_payload(shop)
