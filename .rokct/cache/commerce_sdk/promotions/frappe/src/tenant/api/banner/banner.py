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
# Copyright (c) 2025 ROKCT INTELLIGENCE (PTY) LTD
# For license information, please see license.txt

import frappe


@frappe.whitelist()
def get_banners(page: int=1, limit_page_length: int=10) -> Any:
    """
    Fetches a paginated list of banners.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return frappe.get_all(
        "Banner",
        fields=["name", "title", "image", "url"],
        limit=limit_page_length,
        offset=(page - 1) * limit_page_length,
        order_by="creation desc"
    )


@frappe.whitelist()
def get_banner(id: str) -> Any:
    """
    Fetches a single banner.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return frappe.get_doc("Banner", id)


@frappe.whitelist()
def get_ads(page: int=1) -> Any:
    """
    Fetches a paginated list of banners that are marked as ads.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return frappe.get_all(
        "Banner",
        filters={"is_ad": 1, "is_active": 1},
        fields=["name", "title", "image", "link"],
        limit=10,
        offset=(page - 1) * 10,
    )


@frappe.whitelist()
def get_ad(id: str) -> Any:
    """
    Fetches a single banner that is marked as an ad.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return frappe.get_doc("Banner", id)


@frappe.whitelist()
def like_banner(id: str) -> Any:
    """
    Increments the 'likes' count on a banner.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    banner = frappe.get_doc("Banner", id)
    banner.likes = banner.likes + 1
    banner.save(ignore_permissions=True)
    frappe.db.commit()
    return {"status": "success", "likes": banner.likes}
