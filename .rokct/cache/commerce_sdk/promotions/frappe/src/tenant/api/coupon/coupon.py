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


@frappe.whitelist(allow_guest=True)
def check_coupon(code: str, shop_id: str, qty: int=1) -> Any:
    """
    Checks if a coupon is valid for a given shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    if not code or not shop_id:
        frappe.throw("Code and shop ID are required.")

    coupon = frappe.db.get_value(
        "Coupon",
        filters={"code": code, "shop": shop_id},
        fieldname=["name", "expired_at", "quantity"],
        as_dict=True,
    )

    if not coupon:
        return {"status": "error", "message": "Invalid Coupon"}

    if (
        coupon.get("expired_at")
        and coupon.get("expired_at") < frappe.utils.now_datetime()
    ):
        return {"status": "error", "message": "Coupon expired"}

    if coupon.get("quantity") is not None and coupon.get("quantity") < qty:
        return {"status": "error", "message": "Coupon has been fully used"}

    # Check if the user has already used this coupon
    if frappe.session.user != "Guest" and frappe.db.exists(
        "Coupon Usage", {"user": frappe.session.user, "coupon": coupon.name}
    ):
        return {
            "status": "error",
            "message": "You have already used this coupon.",
        }

    return frappe.get_doc("Coupon", coupon.name).as_dict()
