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
from frappe import _

# Tenant and session.user context isolation validation.

class UserProfile(Document):
	def validate(self):
		if not self.is_new():
			# Check if favorites are being modified
			db_doc = frappe.get_doc("BetAssist User Profile", self.name)
			
			if db_doc.local_favorite_team and self.local_favorite_team != db_doc.local_favorite_team:
				frappe.throw(_("Your local favorite team is permanent and cannot be changed."))
				
			if db_doc.intl_favorite_team and self.intl_favorite_team != db_doc.intl_favorite_team:
				frappe.throw(_("Your international favorite team is permanent and cannot be changed."))
				
		# Synchronize remaining budget if monthly budget is updated for first time
		if self.is_new() or frappe.db.get_value("BetAssist User Profile", self.name, "monthly_budget") != self.monthly_budget:
			if self.is_new():
				self.remaining_budget = self.monthly_budget
			else:
				# Adjust remaining budget proportionally or reset
				old_budget = frappe.db.get_value("BetAssist User Profile", self.name, "monthly_budget") or 0
				diff = self.monthly_budget - old_budget
				self.remaining_budget = max(0, self.remaining_budget + diff)
