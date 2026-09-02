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

"""Tenant proxy for the control-plane rates layer: two thin whitelisted
reads into `src/control/rates/cache.py`'s shared per-pair cache.

**What these serve is reference data.** The rates layer's default source
is the ECB daily reference rate (see src/control/rates/RATES.md) — one
rate per business day, no spread, for display and analysis. Nothing
served here is a tradeable price; live broker pricing arrives through
the broker connector seam in api/account.py.

How the call crosses the control/tenant boundary: `src/control/` is
stripped from tenant-marked shells, so a direct `from ...control.rates`
import would break exactly the builds this file exists for. The existing
pattern for such calls — the weather module's tenant proxy, and
orders' weather_notice.py in this repository — is guarded dynamic
dispatch: `frappe.get_attr` over the composed dotted path, with the
`{app_name}` token substituted by the backend composer. This file does
the same.

Where it deliberately DIFFERS from weather_notice.py: that annotation is
an optional garnish on someone else's payload, so it fails silent. Here
the rate IS the payload, so an uncomposed rates layer raises a clear
error instead of returning nothing that looks like something — the same
no-fabrication rule as api/account.py.
"""

import frappe
from frappe import _

#: composed dotted paths of the control rates cache accessors
#: ({app_name} is substituted by the backend composer).
RATE_SOURCE = "{app_name}.rforex.control.rates.cache.get_cached_rate"
HISTORY_SOURCE = "{app_name}.rforex.control.rates.cache.get_cached_history"

DEFAULT_HISTORY_DAYS = 30


def _resolve(path):
    """frappe.get_attr the composed accessor, or raise the honest error.

    None-or-raise rather than weather_notice's silent None: see the
    module docstring."""
    try:
        source = frappe.get_attr(path)
        if callable(source):
            return source
    except Exception:
        pass
    frappe.throw(
        _("The forex rates layer is not composed into this build."),
        frappe.DoesNotExistError,
    )


@frappe.whitelist()
def get_forex_rate(pair):
    """The latest cached reference rate for one pair.

    Passes the cache dict through unchanged: exactly
    ``{"pair", "bid", "ask", "mid", "ts", "source"}``. A malformed pair
    surfaces as a ValidationError; provider failures propagate as the
    errors they are."""
    source = _resolve(RATE_SOURCE)
    try:
        return source(pair)
    except ValueError as exc:
        # InvalidPair subclasses ValueError precisely so this boundary
        # can catch it without importing control-side classes.
        frappe.throw(str(exc), frappe.ValidationError)


@frappe.whitelist()
def get_forex_history(pair, days=None):
    """Cached daily history rows for one pair — a list of
    ``{"date", "open", "high", "low", "close"}`` dicts, ascending,
    passed through unchanged from the cache. [days] defaults to
    [DEFAULT_HISTORY_DAYS]; validation of both arguments lives in the
    control layer, not here."""
    source = _resolve(HISTORY_SOURCE)
    if days is None or days == "":
        days = DEFAULT_HISTORY_DAYS
    try:
        return source(pair, days)
    except ValueError as exc:
        frappe.throw(str(exc), frappe.ValidationError)
