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
def get_seller_shop_working_days() -> Any:
    """
    Retrieves the working days for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    working_days = frappe.get_all(
        "Shop Working Day",
        filters={"shop": shop},
        fields=["day_of_week", "opening_time", "closing_time", "is_closed"],
    )
    return working_days


@frappe.whitelist()
def update_seller_shop_working_days(working_days_data: Any) -> Any:
    """
    Updates the working days for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(working_days_data, str):
        working_days_data = json.loads(working_days_data)

    # Clear existing working days for the shop
    frappe.db.delete("Shop Working Day", {"shop": shop})

    for day_data in working_days_data:
        frappe.get_doc(
            {"doctype": "Shop Working Day", "shop": shop, **day_data}
        ).insert(ignore_permissions=True)

    return {
        "status": "success",
        "message": "Working days updated successfully.",
    }


@frappe.whitelist()
def get_seller_shop_closed_days() -> Any:
    """
    Retrieves the closed days for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    closed_days = frappe.get_all(
        "Shop Closed Day", filters={"shop": shop}, fields=["date"]
    )
    return [d.date for d in closed_days]


@frappe.whitelist()
def add_seller_shop_closed_day(date: Any) -> Any:
    """
    Adds a closed day for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    frappe.get_doc(
        {"doctype": "Shop Closed Day", "shop": shop, "date": date}
    ).insert(ignore_permissions=True)

    return {"status": "success", "message": "Closed day added successfully."}


@frappe.whitelist()
def delete_seller_shop_closed_day(date: Any) -> Any:
    """
    Deletes a closed day for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    frappe.db.delete("Shop Closed Day", {"shop": shop, "date": date})

    return {"status": "success", "message": "Closed day deleted successfully."}


@frappe.whitelist()
def get_shop_users(search: Optional[str]=None, role: Optional[str]=None, limit_start: int=0, limit_page_length: int=20) -> Any:
    """
    Retrieves a list of users for the current seller's shop.

    Shop-scoped (pre-fork paas behavior): only members of the calling
    seller's own shop are ever returned. Optional `search` filters by
    name/email/phone and optional `role` filters by the member's shop role;
    both are additive so plain `get_shop_users()` keeps the legacy
    membership listing. Rows carry the legacy `user`/`role` keys plus the
    user detail fields the manager POS customer picker renders.

    Schema note: the composed half has no full-text index, so `search` uses
    portable LIKE matching over User first_name/last_name/full_name/email/
    phone instead of the legacy Postgres tsvector query.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    membership_filters = {"shop": shop}
    if role:
        membership_filters["role"] = role

    memberships = frappe.get_all(
        "User Shop",
        filters=membership_filters,
        fields=["user", "role"],
    )
    if not memberships:
        return []
    role_by_user = {m.user: m.role for m in memberships}

    user_filters = {"name": ["in", list(role_by_user)]}
    or_filters = None
    if search:
        like = f"%{search}%"
        or_filters = [
            ["User", "first_name", "like", like],
            ["User", "last_name", "like", like],
            ["User", "full_name", "like", like],
            ["User", "email", "like", like],
            ["User", "phone", "like", like],
        ]

    users = frappe.get_all(
        "User",
        filters=user_filters,
        or_filters=or_filters,
        fields=[
            "name",
            "first_name",
            "last_name",
            "full_name",
            "email",
            "phone",
            "user_image",
            "enabled",
        ],
        limit_start=limit_start,
        limit=limit_page_length,
        order_by="full_name asc",
    )

    return [
        {
            "user": u.name,
            "role": role_by_user.get(u.name),
            "id": u.name,
            "firstname": u.first_name,
            "lastname": u.last_name,
            "full_name": u.full_name,
            "email": u.email,
            "phone": u.phone,
            "img": u.user_image,
            "active": u.enabled,
        }
        for u in users
    ]


@frappe.whitelist()
def add_shop_user(user_email: str, role: str) -> Any:
    """
    The add_shop_user function is used to add a user to the current seller's shop with a specific role. It takes two parameters: user_email, which is the email address of the user to be added, and role, which defines the user's role within the shop. The function first checks if the user exists and if they are not already a member of the shop, then adds the user to the shop with the specified role. If the operation is successful, it returns a success status with a corresponding message.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    trace_id = None
    """
    Adds a user to the current seller's shop with a specific role.
    """
    owner = frappe.session.user
    shop = _get_seller_shop(owner)

    user_to_add = frappe.db.get_value("User", {"email": user_email}, "name")
    if not user_to_add:
        frappe.throw("User not found.")

    if frappe.db.exists("User Shop", {"user": user_to_add, "shop": shop}):
        frappe.throw("User is already a member of this shop.")

    frappe.get_doc(
        {
            "doctype": "User Shop",
            "user": user_to_add,
            "shop": shop,
            "role": role,
        }
    ).insert(ignore_permissions=True)

    return {"status": "success", "message": "User added to shop successfully."}


@frappe.whitelist()
def remove_shop_user(user_to_remove: str) -> Any:
    """
    Removes a user from the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    owner = frappe.session.user
    shop = _get_seller_shop(owner)

    frappe.db.delete("User Shop", {"user": user_to_remove, "shop": shop})

    return {
        "status": "success",
        "message": "User removed from shop successfully.",
    }


@frappe.whitelist()
def get_seller_branches(limit_start: int=0, limit_page_length: int=20) -> Any:
    """
    Retrieves a list of branches for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    branches = frappe.get_list(
        "Branch",
        filters={"shop": shop},
        fields=["name", "branch_name", "address", "latitude", "longitude"],
        offset=limit_start,
        limit=limit_page_length,
        order_by="name",
    )
    return branches


@frappe.whitelist()
def create_seller_branch(branch_data: Any) -> Any:
    """
    Creates a new branch for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(branch_data, str):
        branch_data = json.loads(branch_data)

    branch_data["shop"] = shop
    branch_data["owner"] = user

    new_branch = frappe.get_doc({"doctype": "Branch", **branch_data})
    new_branch.insert(ignore_permissions=True)
    return new_branch.as_dict()


@frappe.whitelist()
def update_seller_branch(branch_name: Any, branch_data: Any) -> Any:
    """
    Updates a branch for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(branch_data, str):
        branch_data = json.loads(branch_data)

    branch = frappe.get_doc("Branch", branch_name)

    if branch.shop != shop:
        frappe.throw(
            "You are not authorized to update this branch.",
            frappe.PermissionError,
        )

    branch.update(branch_data)
    branch.save(ignore_permissions=True)
    return branch.as_dict()


@frappe.whitelist()
def delete_seller_branch(branch_name: Any) -> Any:
    """
    Deletes a branch for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    branch = frappe.get_doc("Branch", branch_name)

    if branch.shop != shop:
        frappe.throw(
            "You are not authorized to delete this branch.",
            frappe.PermissionError,
        )

    frappe.delete_doc("Branch", branch_name, ignore_permissions=True)
    return {"status": "success", "message": "Branch deleted successfully."}


@frappe.whitelist()
def get_seller_deliveryman_settings() -> Any:
    """
    Retrieves the deliveryman settings for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if not frappe.db.exists("Shop Deliveryman Settings", {"shop": shop}):
        return {}

    return frappe.get_doc(
        "Shop Deliveryman Settings", {"shop": shop}
    ).as_dict()


@frappe.whitelist()
def update_seller_deliveryman_settings(settings_data: Any) -> Any:
    """
    Updates the deliveryman settings for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(settings_data, str):
        settings_data = json.loads(settings_data)

    if not frappe.db.exists("Shop Deliveryman Settings", {"shop": shop}):
        settings = frappe.new_doc("Shop Deliveryman Settings")
        settings.shop = shop
    else:
        settings = frappe.get_doc("Shop Deliveryman Settings", {"shop": shop})

    settings.update(settings_data)
    settings.save(ignore_permissions=True)
    return settings.as_dict()


# --- ALIASES FOR FLUTTER ENDPOINTS ---


@frappe.whitelist()
def update_shop_working_days(working_days_data: Any=None) -> Any:
    """
    Update shop working days API endpoint.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    return update_seller_shop_working_days(working_days_data)
