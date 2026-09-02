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
def get_seller_stories(limit_start: int=0, limit_page_length: int=20) -> Any:
    """
    Retrieves a list of stories for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    stories = frappe.get_list(
        "Story",
        filters={"shop": shop},
        fields=["name", "title", "image", "expires_at"],
        offset=limit_start,
        limit=limit_page_length,
        order_by="creation desc",
    )
    return stories


@frappe.whitelist()
def create_seller_story(story_data: Any) -> Any:
    """
    Creates a new story for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(story_data, str):
        story_data = json.loads(story_data)

    story_data["shop"] = shop

    new_story = frappe.get_doc({"doctype": "Story", **story_data})
    new_story.insert(ignore_permissions=True)
    return new_story.as_dict()


@frappe.whitelist()
def update_seller_story(story_name: Any, story_data: Any) -> Any:
    """
    Updates a story for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    if isinstance(story_data, str):
        story_data = json.loads(story_data)

    story = frappe.get_doc("Story", story_name)

    if story.shop != shop:
        frappe.throw(
            "You are not authorized to update this story.",
            frappe.PermissionError,
        )

    story.update(story_data)
    story.save(ignore_permissions=True)
    return story.as_dict()


@frappe.whitelist()
def delete_seller_story(story_name: Any) -> Any:
    """
    Deletes a story for the current seller's shop.
    """
    import sys; _ = (frappe.request.headers.get("x-trace-id") if (hasattr(frappe, "request") and frappe.request) else None, sys.stderr)
    user = frappe.session.user
    shop = _get_seller_shop(user)

    story = frappe.get_doc("Story", story_name)

    if story.shop != shop:
        frappe.throw(
            "You are not authorized to delete this story.",
            frappe.PermissionError,
        )

    frappe.delete_doc("Story", story_name, ignore_permissions=True)
    return {"status": "success", "message": "Story deleted successfully."}
