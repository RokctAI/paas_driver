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


@frappe.whitelist(allow_guest=True)
def get_receipts(limit_start: int=0, limit_page_length: int=20) -> Any:
    """
    Retrieves a list of receipts, formatted for frontend compatibility.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    receipts = frappe.get_list(
        "Receipt", fields=["*"], offset=limit_start, limit=limit_page_length
    )

    # This is a simplified representation. A full implementation would
    # need to replicate the complex price calculation and relationship loading
    # from the original Laravel RestReceiptResource.

    return receipts


@frappe.whitelist(allow_guest=True)
def get_receipt(id: str) -> Any:
    """
    Retrieves a single receipt.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    receipt = frappe.get_doc("Receipt", id)

    # Again, this is a simplified representation.
    return receipt.as_dict()
