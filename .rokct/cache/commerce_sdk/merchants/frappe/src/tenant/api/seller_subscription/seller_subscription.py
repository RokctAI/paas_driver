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
def attach_subscription(subscription_data: Any=None) -> Any:
    """
    Attach subscription API endpoint.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return {"status": True}


@frappe.whitelist()
def get_subscriptions(limit_start: Any=0, limit_page_length: Any=20) -> Any:
    """
    Get subscriptions API endpoint.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    if frappe.db.exists("DocType", "Subscription"):
        return frappe.get_all("Subscription", fields=["*"])
    return []


@frappe.whitelist()
def create_subscription_transaction(transaction_data: Any=None) -> Any:
    """
    Create subscription transaction API endpoint.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return {"status": True}
