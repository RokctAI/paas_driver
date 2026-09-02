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

"""Control-plane outcome ledger for the forex SDK.

ledger.py — every emitted signal logged against what actually happened
            (append-once verdicts, DocType storage when composed,
            in-memory otherwise).
report.py — the ledger read back honestly, per immutable strategy version.
frozen.py — the FrozenConfigError / HoldoutAccessError guards that keep
            retuning on the new-version path and the backtest holdout
            single-use. Protocol: forex/BACKTEST.md.
"""
