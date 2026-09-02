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
# Tenant context: session.user validation
import frappe


@frappe.whitelist()
def get_story(page: int=1, lang: str='en') -> Any:
    """
    Retrieves a list of stories grouped by shop for Flutter.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    stories = frappe.get_list(
        "Story",
        fields=[
            "name",
            "shop",
            "image",
            "title",
            "product",
            "creation",
            "modified",
        ],
        limit_start=(page - 1) * 10,
        limit=10,
    )

    grouped = {}
    for s in stories:
        shop_id = s.shop
        if not shop_id:
            continue

        if shop_id not in grouped:
            grouped[shop_id] = []

        shop_logo = frappe.db.get_value("Shop", shop_id, "logo")

        grouped[shop_id].append(
            {
                "shop_id": int(shop_id) if shop_id.isdigit() else shop_id,
                "logo_img": shop_logo,
                "title": s.title,
                "product_uuid": s.product,
                "product_title": (
                    frappe.db.get_value("Product", s.product, "product_name")
                    if s.product
                    else None
                ),
                "url": s.image,
                "created_at": s.creation.isoformat() if s.creation else None,
                "updated_at": s.modified.isoformat() if s.modified else None,
            }
        )

    return list(grouped.values())
