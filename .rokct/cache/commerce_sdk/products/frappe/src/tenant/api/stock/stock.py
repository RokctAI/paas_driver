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
import json


@frappe.whitelist()
def create_stock(data: Any) -> Any:
    """
    Creates a new Stock (Variant) for a Product.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    if isinstance(data, str):
        data = json.loads(data)

    # Extract extras if present
    extras = data.pop("extras", [])

    doc = frappe.get_doc({"doctype": "Stock", **data})

    # Add extras to child table
    for extra_value_id in extras:
        doc.append("stock_extras", {"extra_value": extra_value_id})

    doc.insert()
    return doc.as_dict()


@frappe.whitelist()
def get_product_stocks(product_id: Any) -> Any:
    """
    Retrieves all Stock variants for a Product.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return frappe.get_list(
        "Stock", filters={"product": product_id}, fields=["*"]
    )


@frappe.whitelist()
def update_stock(name: Any, data: Any) -> Any:
    """
    Updates a Stock item.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    if isinstance(data, str):
        data = json.loads(data)

    doc = frappe.get_doc("Stock", name)

    # Handle extras update if provided
    if "extras" in data:
        extras = data.pop("extras")
        doc.set("stock_extras", [])  # Clear existing
        for extra_value_id in extras:
            doc.append("stock_extras", {"extra_value": extra_value_id})

    doc.update(data)
    doc.save()
    return doc.as_dict()


@frappe.whitelist()
def delete_stock(name: Any) -> Any:
    """
    Deletes a Stock item.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    frappe.delete_doc("Stock", name)
    return {"status": "success"}
