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

"""process_repeating_orders charging a saved card, without a bench.

The repeating-orders scheduler is the visible casualty of pay's
saved-card credential confinement. `Saved Card.token` is the gateway
reuse credential -- whoever holds it can charge that card again -- so it
became a Frappe `Password` field. Frappe then keeps the real value
encrypted in `__Auth` and leaves one asterisk per character in the
doctype column, which means:

* `card.token` off a fetched document yields the MASK, not a credential;
* the old reverse lookup on `{"token": ...}` cannot match anything;
* `process_token_payment` is keyed on the Saved Card docname instead and
  takes it as `saved_card=`.

So this task must name the card, not carry a secret. The stub pay module
below is deliberately faithful to that post-change contract: it resolves
`saved_card` as a docname and refuses anything else WITHOUT charging.
A caller still reaching for `card.token` hands it the mask, the mask is
not a docname, and the charge is refused -- repeating orders silently
stop paying. That is the failure these tests exist to catch.

Mirrors tests/test_create_order_payment.py's stub-frappe approach:
tasks.py is templated composed source (`from {app_name}... import` lines),
so the file is read, the `{app_name}` token substituted with a stub
package name, and the result exec'd over in-memory stubs. The suite skips
itself when the real frappe package is importable (a bench context).

No real credential value appears anywhere in this file. The stand-in
credential is a literal row of asterisks -- which is exactly what a
Password column actually holds.

Run standalone:
    python3 -m unittest tests.test_repeating_order_saved_card_charge
"""

import importlib.util
import os
import sys
import types
import unittest
from datetime import datetime, timedelta

HAVE_REAL_FRAPPE = importlib.util.find_spec("frappe") is not None

_MODULE_PATH = os.path.join(
    os.path.dirname(__file__), "..", "src", "tenant", "tasks.py"
)

_STUB_APP = "rokct_repeating_order_test_app"
_PAY_MODULE = _STUB_APP + ".wallet.tenant.api.payment.payment"
_NOTIFY_MODULE = _STUB_APP + ".comms.tenant.api.notification.notification"

_NOW = datetime(2026, 8, 30, 9, 0, 0)

# What a Frappe `Password` column actually contains once the real value
# has moved into the encrypted store: one asterisk per character. Reading
# `card.token` off a document yields THIS. It is not a credential and it
# is not a docname, so a charge keyed on it is refused.
_MASK = "*" * 36


class _AttrDict(dict):
    """frappe.get_all rows: mapping access plus ro.name attribute access."""

    def __getattr__(self, key):
        try:
            return self[key]
        except KeyError:
            raise AttributeError(key)


class _Doc(types.SimpleNamespace):
    """Just enough of frappe.model.document.Document."""

    def get(self, key, default=None):
        return getattr(self, key, default)

    def set(self, key, value):
        setattr(self, key, value)

    def save(self, ignore_permissions=False):
        return self


def _install_stub_packages():
    """Install the composed-app stub packages tasks.py imports from."""

    def module(name, **attrs):
        mod = sys.modules.get(name) or types.ModuleType(name)
        for key, val in attrs.items():
            setattr(mod, key, val)
        sys.modules[name] = mod
        return mod

    for pkg in (
        _STUB_APP,
        _STUB_APP + ".wallet",
        _STUB_APP + ".wallet.tenant",
        _STUB_APP + ".wallet.tenant.api",
        _STUB_APP + ".wallet.tenant.api.payment",
        _STUB_APP + ".comms",
        _STUB_APP + ".comms.tenant",
        _STUB_APP + ".comms.tenant.api",
        _STUB_APP + ".comms.tenant.api.notification",
    ):
        module(pkg)


def _install_stub_croniter():
    mod = types.ModuleType("croniter")

    class croniter:
        def __init__(self, pattern, start):
            self.pattern = pattern
            self.start = start

        def get_next(self, _type=None):
            return self.start + timedelta(days=1)

    mod.croniter = croniter
    sys.modules["croniter"] = mod


def _install_stub_frappe():
    frappe = types.ModuleType("frappe")

    class ValidationError(Exception):
        pass

    class DoesNotExistError(Exception):
        pass

    class PermissionError_(Exception):
        pass

    frappe.ValidationError = ValidationError
    frappe.DoesNotExistError = DoesNotExistError
    frappe.PermissionError = PermissionError_

    def throw(msg, exc=ValidationError):
        raise exc(msg)

    frappe.throw = throw

    def whitelist(allow_guest=False, **kwargs):
        def wrap(fn):
            return fn

        return wrap

    frappe.whitelist = whitelist
    frappe.session = types.SimpleNamespace(user="Administrator")
    frappe.conf = {"app_role": "tenant"}
    frappe.utils = types.SimpleNamespace(now_datetime=lambda: _NOW)

    frappe._docs = {}          # (doctype, name) -> _Doc
    frappe._inserted = []      # docs inserted, in order
    frappe._rows = {}          # doctype -> list of _AttrDict for get_all
    frappe._set_values = []    # (doctype, name, field_or_dict, value)
    frappe._users = []         # frappe.set_user() calls
    frappe._log_errors = []

    def set_user(user):
        frappe._users.append(user)
        frappe.session.user = user

    frappe.set_user = set_user

    def get_all(doctype, filters=None, fields=None, pluck=None, **kwargs):
        rows = list(frappe._rows.get(doctype, []))
        if pluck:
            return [r[pluck] for r in rows]
        return rows

    frappe.get_all = get_all

    def _insert_factory(doc):
        def insert(ignore_permissions=False, _doc=doc):
            _doc.name = "{0}-{1:04d}".format(
                getattr(_doc, "doctype", "DOC"), len(frappe._inserted) + 1
            )
            frappe._inserted.append(_doc)
            frappe._docs[(_doc.doctype, _doc.name)] = _doc
            return _doc

        return insert

    def get_doc(*args, **kwargs):
        if len(args) == 1 and isinstance(args[0], dict):
            doc = _Doc(**dict(args[0]))
            doc.name = None
            doc.insert = _insert_factory(doc)
            return doc
        doctype, name = args[0], args[1]
        doc = frappe._docs.get((doctype, name))
        if doc is None:
            raise DoesNotExistError("{0} {1} not found".format(doctype, name))
        return doc

    frappe.get_doc = get_doc

    def copy_doc(doc):
        copy = _Doc(**dict(doc.__dict__))
        copy.name = None
        copy.insert = _insert_factory(copy)
        return copy

    frappe.copy_doc = copy_doc

    def db_set_value(doctype, name, field, value=None, **kwargs):
        frappe._set_values.append((doctype, name, field, value))

    frappe.db = types.SimpleNamespace(
        set_value=db_set_value,
        commit=lambda: None,
        get_value=lambda *a, **k: None,
    )

    frappe.delete_doc = lambda *a, **k: None
    frappe.get_traceback = lambda: "traceback"

    def log_error(*args, **kwargs):
        frappe._log_errors.append((args, kwargs))

    frappe.log_error = log_error

    frappe.__path__ = []
    model = types.ModuleType("frappe.model")
    model.__path__ = []
    document = types.ModuleType("frappe.model.document")
    document.Document = _Doc
    model.document = document
    frappe.model = model
    utils_mod = types.ModuleType("frappe.utils")
    utils_mod.now_datetime = lambda: _NOW
    frappe.utils = utils_mod

    sys.modules["frappe"] = frappe
    sys.modules["frappe.model"] = model
    sys.modules["frappe.model.document"] = document
    sys.modules["frappe.utils"] = utils_mod
    return frappe


def _load_tasks_module():
    with open(os.path.abspath(_MODULE_PATH)) as fh:
        source = fh.read().replace("{app_name}", _STUB_APP)
    module = types.ModuleType("repeating_orders_under_test")
    module.__file__ = os.path.abspath(_MODULE_PATH)
    module.__package__ = ""
    exec(compile(source, _MODULE_PATH, "exec"), module.__dict__)
    return module


@unittest.skipIf(
    HAVE_REAL_FRAPPE,
    "real frappe importable -- run FrappeTestCase suites under bench",
)
class RepeatingOrderSavedCardChargeBase(unittest.TestCase):
    USER = "buyer@example.com"
    CARD = "SAVED-CARD-0001"

    @classmethod
    def setUpClass(cls):
        cls.frappe = _install_stub_frappe()
        _install_stub_packages()
        _install_stub_croniter()
        cls.tasks = _load_tasks_module()

    def setUp(self):
        f = self.frappe
        f._docs.clear()
        f._inserted.clear()
        f._rows.clear()
        f._set_values.clear()
        f._users.clear()
        f._log_errors.clear()
        f.session = types.SimpleNamespace(user="Administrator")

        # The charges the stub pay module was asked to perform.
        self.charges = []
        # The push notifications the task sent.
        self.notifications = []

        # The saved card, as it reads AFTER the credential moved into the
        # encrypted store: `token` on the document is the mask.
        f._docs[("Saved Card", self.CARD)] = _Doc(
            doctype="Saved Card",
            name=self.CARD,
            user=self.USER,
            gateway="PayFast",
            last_four="4242",
            card_type="Visa",
            token=_MASK,
        )
        f._docs[("Order", "ORD-ORIGINAL")] = _Doc(
            doctype="Order",
            name="ORD-ORIGINAL",
            user=self.USER,
            shop="SHOP-1",
            grand_total=250.0,
            status="Delivered",
            payment_status="Paid",
        )
        f._docs[("User", self.USER)] = _Doc(
            doctype="User",
            name=self.USER,
            wallet_balance=0.0,
            ringfenced_balance=0.0,
        )
        self.install_pay_module()
        self.install_notification_module()

    # -- stubs mirroring the post-change pay contract -------------------

    def install_pay_module(self):
        """Stand in for pay's payment module, post-confinement.

        Signature and behaviour follow the shipped one: `saved_card` is
        the Saved Card docname, `token` is accepted only to refuse an
        unconverted caller by name. Neither path charges anything it
        cannot resolve to a card row.
        """

        def process_token_payment(order_id, saved_card=None, token=None):
            self.charges.append(
                {"order_id": order_id, "saved_card": saved_card,
                 "token": token}
            )
            if not saved_card and token:
                raise ValueError(
                    "process_token_payment no longer accepts a `token`: "
                    "the gateway reuse credential is server-side only. "
                    "Pass `saved_card`. No charge was performed."
                )
            card = self.frappe._docs.get(("Saved Card", saved_card))
            if card is None or card.user != self.frappe.session.user:
                # One message for "no such card" and "not your card", as
                # the shipped endpoint does.
                raise ValueError("Invalid or unauthorized saved card.")
            return {"status": "success", "transaction_id": "TXN-0001"}

        mod = types.ModuleType(_PAY_MODULE)
        mod.process_token_payment = process_token_payment
        sys.modules[_PAY_MODULE] = mod
        sys.modules[_STUB_APP + ".wallet.tenant.api.payment"].payment = mod
        return mod

    def install_notification_module(self):
        def send_push_notification(user=None, title=None, body=None,
                                   data=None):
            self.notifications.append(
                {"user": user, "title": title, "body": body, "data": data}
            )

        mod = types.ModuleType(_NOTIFY_MODULE)
        mod.send_push_notification = send_push_notification
        sys.modules[_NOTIFY_MODULE] = mod
        parent = sys.modules[_STUB_APP + ".comms.tenant.api.notification"]
        parent.notification = mod
        return mod

    # -- fixtures -------------------------------------------------------

    def due_repeating_order(self, **overrides):
        row = {
            "name": "REPEAT-0001",
            "user": self.USER,
            "original_order": "ORD-ORIGINAL",
            "cron_pattern": "0 0 * * *",
            "next_execution": _NOW,
            "end_date": None,
            "payment_method": "Saved Card",
            "saved_card": self.CARD,
            "ringfenced_amount": 0.0,
        }
        row.update(overrides)
        self.frappe._rows["Repeating Order"] = [_AttrDict(row)]
        return row

    def inserted_orders(self):
        return [d for d in self.frappe._inserted if d.doctype == "Order"]

    def failure_notifications(self):
        return [
            n for n in self.notifications
            if "Payment Failed" in (n["title"] or "")
        ]


class TestRepeatingOrderChargesTheSavedCard(
    RepeatingOrderSavedCardChargeBase
):
    def test_a_due_repeat_order_on_a_saved_card_is_charged_end_to_end(self):
        """The behaviour a user notices: the repeat order actually pays.

        Fails if the task still reaches for the credential -- the mask is
        not a docname, the charge is refused, and the order lands in the
        payment-failed lane with a push notification.
        """
        self.due_repeating_order()

        self.tasks.process_repeating_orders()

        orders = self.inserted_orders()
        self.assertEqual(
            len(orders), 1, "the scheduler should create exactly one order"
        )
        self.assertEqual(
            len(self.charges), 1, "the card should be charged exactly once"
        )
        self.assertEqual(
            self.charges[0]["order_id"],
            orders[0].name,
            "the charge should name the order the scheduler just created",
        )
        self.assertEqual(
            self.failure_notifications(),
            [],
            "a successful charge must not notify the user of a failure",
        )
        # The repeating order was advanced, i.e. the run counted.
        advanced = [
            s for s in self.frappe._set_values
            if s[0] == "Repeating Order" and isinstance(s[2], dict)
            and "next_execution" in s[2]
        ]
        self.assertEqual(
            len(advanced), 1,
            "a paid run should advance the repeating order's schedule",
        )

    def test_the_charge_names_the_card_and_carries_no_credential(self):
        """The charge handle is the Saved Card docname, nothing else."""
        self.due_repeating_order()

        self.tasks.process_repeating_orders()

        self.assertEqual(len(self.charges), 1)
        charge = self.charges[0]
        self.assertEqual(
            charge["saved_card"],
            self.CARD,
            "the charge should be keyed on the Saved Card docname",
        )
        self.assertIsNone(
            charge["token"],
            "no credential-shaped argument should be sent at all",
        )

    def test_no_masked_or_secret_value_reaches_the_payment_endpoint(self):
        """Nothing the task sends may be the doctype column's contents.

        This is the regression in its plainest form: `card.token` reads
        the mask off the document, and passing the mask along is how the
        repeating-orders path stops charging.
        """
        self.due_repeating_order()

        self.tasks.process_repeating_orders()

        for charge in self.charges:
            for key, value in charge.items():
                self.assertNotEqual(
                    value, _MASK,
                    "{0} carried the Password column's masked contents "
                    "to the payment endpoint".format(key),
                )

    def test_the_task_runs_the_charge_as_the_cards_owner(self):
        """Ownership is checked server-side against the session user."""
        self.due_repeating_order()

        self.tasks.process_repeating_orders()

        self.assertIn(
            self.USER,
            self.frappe._users,
            "the charge must run in the repeating order owner's context",
        )
        self.assertEqual(len(self.charges), 1)


class TestRepeatingOrderChargeGuards(RepeatingOrderSavedCardChargeBase):
    """Guards: behaviour that must NOT change with the handle swap."""

    def test_an_unknown_card_fails_closed_without_paying(self):
        self.due_repeating_order(saved_card="NO-SUCH-CARD")

        self.tasks.process_repeating_orders()

        self.assertEqual(
            len(self.failure_notifications()), 1,
            "an unchargeable card must notify the user, not pass silently",
        )

    def test_a_card_belonging_to_someone_else_is_not_charged(self):
        self.frappe._docs[("Saved Card", self.CARD)].user = "mallory@e.com"
        self.due_repeating_order()

        self.tasks.process_repeating_orders()

        self.assertEqual(
            len(self.failure_notifications()), 1,
            "another user's card must not pay this user's repeat order",
        )

    def test_the_ringfenced_wallet_path_still_pays(self):
        self.due_repeating_order(
            payment_method="Wallet", ringfenced_amount=500.0, saved_card=None
        )

        self.tasks.process_repeating_orders()

        self.assertEqual(
            self.charges, [], "the wallet path must not touch a card"
        )
        self.assertEqual(
            self.failure_notifications(), [],
            "sufficient ringfenced funds should pay the order",
        )
        orders = self.inserted_orders()
        self.assertEqual(len(orders), 1)
        self.assertEqual(orders[0].payment_status, "Paid")

    def test_a_saved_card_method_with_no_card_is_not_charged(self):
        self.due_repeating_order(saved_card=None)

        self.tasks.process_repeating_orders()

        self.assertEqual(
            self.charges, [], "no card named means no charge attempted"
        )
        self.assertEqual(len(self.failure_notifications()), 1)


if __name__ == "__main__":
    unittest.main()
