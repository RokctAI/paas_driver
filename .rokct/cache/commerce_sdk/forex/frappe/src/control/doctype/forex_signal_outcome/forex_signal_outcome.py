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

# Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
# For license information, please see license.txt

"""One outcome-ledger row.

Writes go through outcomes/ledger.py (record_signal / record_outcome),
which owns the vocabulary and refusal rules; this controller repeats only
the property the desk could otherwise silently break: **a settled verdict
is written once.** Editing a settled row's result fields is refused even
for System Manager — an outcome ledger that can be massaged after the
fact is not evidence, the same reason a published Forex Strategy Version
refuses spec edits. A correction is a new row plus a note in meta.
"""

import frappe
from frappe import _
from frappe.model.document import Document

#: the fields a verdict consists of. Once `outcome` is set in the database,
#: none of these may change.
_VERDICT_FIELDS = ("outcome", "exit_ts", "exit_price", "pips",
                   "outcome_meta", "settled_at")


class ForexSignalOutcome(Document):
    def validate(self):
        if self.is_new():
            return
        if not self.get_db_value("outcome"):
            return
        for fieldname in _VERDICT_FIELDS:
            if self.has_value_changed(fieldname):
                frappe.throw(
                    _(
                        "This signal is settled and its verdict is frozen "
                        "({0} changed). The ledger is append-once: record a "
                        "correction as a note on a new row, never as an "
                        "edit."
                    ).format(fieldname)
                )

    def on_trash(self):
        # Deleting settled evidence is the other way to massage a ledger.
        if self.outcome:
            frappe.throw(
                _(
                    "Settled outcome rows are evidence and are not deleted. "
                    "If this row is wrong, record the correction in a new "
                    "row's meta."
                )
            )
