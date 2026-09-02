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

import frappe
from frappe.model.document import Document
from frappe.utils import add_days, getdate, today
from frappe import _

# Tenant and session.user context isolation validation.

class FollowedTeam(Document):
	def before_insert(self):
		# Prevent duplicates
		exists = frappe.db.exists("BetAssist Followed Team", {"user": self.user, "team": self.team})
		if exists:
			frappe.throw(_("You are already following this team."))

	def on_trash(self):
		# Enforce "unfollow once per week" rule
		# We check if there's a log of them unfollowing this team in the last 7 days.
		last_unfollow = frappe.db.get_value(
			"BetAssist Unfollow Log",
			{"user": self.user, "team": self.team},
			"unfollowed_date",
			order_by="unfollowed_date desc"
		)
		
		if last_unfollow:
			seven_days_ago = add_days(getdate(today()), -7)
			if getdate(last_unfollow) > seven_days_ago:
				frappe.throw(_("You can only unfollow this team once per week. Please wait before unfollowing again."))
		
		# Record the unfollow log
		log = frappe.get_doc({
			"doctype": "BetAssist Unfollow Log",
			"user": self.user,
			"team": self.team,
			"unfollowed_date": today()
		})
		log.insert(ignore_permissions=True)
