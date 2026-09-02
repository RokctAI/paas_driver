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

"""create_order payment wiring, unit-tested without a bench.

Covers the ``payment_id`` handoff from ``create_order`` to pay's
``create_order_transaction`` (the composed ``{app_name}.wallet.tenant
.api.payment`` module): recording on a provided gateway, the no-op for
payment-less orders, the Guest skip, the not-composed (unmigrated
site) log-and-skip meta-guard, and error propagation from the real
recorder.

Mirrors tests/test_settlement.py's stub-frappe approach, with one
extra step: ``order.py`` is templated composed source (top-level
``from {app_name}... import`` lines), so the file is read, the
``{app_name}`` token substituted with a stub package name, and the
result exec'd over in-memory stub packages that stand in for the
composed base and pay wallet modules. The suite skips itself when the
real frappe package is importable (a bench context).

Run standalone:
    python3 -m unittest orders/frappe/tests/test_create_order_payment.py
"""

import importlib.util
import os
import sys
import types
import unittest
from datetime import datetime

HAVE_REAL_FRAPPE = importlib.util.find_spec("frappe") is not None

_MODULE_PATH = os.path.join(
    os.path.dirname(__file__),
    "..", "src", "tenant", "api", "order", "order.py",
)

# The composed-app package name the {app_name} token is substituted
# with; stub sub-packages are installed under it in sys.modules.
_STUB_APP = "rokct_order_test_app"

_PAY_MODULE = _STUB_APP + ".wallet.tenant.api.payment"


class _Doc(types.SimpleNamespace):
    """Just enough of frappe.model.document.Document."""

    def get(self, key, default=None):
        return getattr(self, key, default)

    def db_set(self, field, value):
        setattr(self, field, value)

    def save(self, ignore_permissions=False):
        return self

    def reload(self):
        log = getattr(self, "_reload_log", None)
        if log is not None:
            log.append(self.name)
        return self


def _install_stub_packages():
    """Install the composed-app stub packages order.py imports from."""

    def module(name, **attrs):
        mod = sys.modules.get(name) or types.ModuleType(name)
        for key, val in attrs.items():
            setattr(mod, key, val)
        sys.modules[name] = mod
        return mod

    for pkg in (
        _STUB_APP,
        _STUB_APP + ".base",
        _STUB_APP + ".base.tenant",
        _STUB_APP + ".base.tenant.api",
        _STUB_APP + ".wallet",
        _STUB_APP + ".wallet.tenant",
        _STUB_APP + ".wallet.tenant.api",
    ):
        module(pkg)

    def api_response(data=None, message=None, **kwargs):
        return {"data": data, "message": message}

    def idempotent(fn):
        return fn

    module(
        _STUB_APP + ".base.tenant.api.utils", api_response=api_response
    )
    module(
        _STUB_APP + ".base.tenant.api.idempotency", idempotent=idempotent
    )
    # The pay wallet payment module is installed/removed per-test.


def _install_stub_frappe():
    frappe = types.ModuleType("frappe")

    class ValidationError(Exception):
        pass

    class DoesNotExistError(Exception):
        pass

    frappe.ValidationError = ValidationError
    frappe.DoesNotExistError = DoesNotExistError

    def throw(msg, exc=ValidationError):
        raise exc(msg)

    frappe.throw = throw

    def whitelist(allow_guest=False, **kwargs):
        def wrap(fn):
            return fn

        return wrap

    frappe.whitelist = whitelist
    frappe.session = types.SimpleNamespace(user="buyer@example.com")
    frappe.get_roles = lambda user=None: []
    frappe.utils = types.SimpleNamespace(
        now_datetime=lambda: datetime(2026, 8, 28, 12, 0, 0),
        getdate=lambda value=None: datetime(2026, 8, 28).date(),
    )

    frappe._docs = {}  # (doctype, name) -> _Doc
    frappe._inserted = []
    frappe._singles = {}  # doctype -> _Doc
    frappe._log_errors = []  # (title, message)
    frappe._reloads = []  # order names reload()ed
    frappe._calls = []  # frappe.call invocations

    def get_single(doctype):
        return frappe._singles[doctype]

    frappe.get_single = get_single

    def db_get_value(doctype, filters, fieldname="name", **kwargs):
        if isinstance(filters, dict):
            for (dt, _name), doc in sorted(frappe._docs.items()):
                if dt != doctype:
                    continue
                if all(
                    getattr(doc, k, None) == v for k, v in filters.items()
                ):
                    return getattr(doc, fieldname, None)
            return None
        doc = frappe._docs.get((doctype, filters))
        if doc is None:
            return None
        return getattr(doc, fieldname, None)

    def db_exists(doctype, name):
        if isinstance(name, dict):
            for (dt, _n), doc in frappe._docs.items():
                if dt == doctype and all(
                    getattr(doc, k, None) == v for k, v in name.items()
                ):
                    return doc.name
            return None
        return name if (doctype, name) in frappe._docs else None

    frappe.db = types.SimpleNamespace(
        get_value=db_get_value,
        exists=db_exists,
        count=lambda doctype, filters=None: 0,
        commit=lambda: None,
    )

    def get_doc(*args, **kwargs):
        if len(args) == 1 and isinstance(args[0], dict):
            doc = _Doc(**dict(args[0]))
            doc._reload_log = frappe._reloads
            rows_key = "order_items"
            setattr(doc, rows_key, [])

            def append(field, row, _doc=doc):
                getattr(_doc, field).append(_Doc(**row))

            def insert(ignore_permissions=False, _doc=doc):
                _doc.name = "{0}-{1:04d}".format(
                    _doc.doctype, len(frappe._inserted) + 1
                )
                if getattr(_doc, "doctype", None) == "Order" and not getattr(
                    _doc, "total_price", None
                ):
                    _doc.total_price = sum(
                        float(r.price or 0) * float(r.quantity or 0)
                        for r in _doc.order_items
                    )
                frappe._inserted.append(_doc)
                frappe._docs[(_doc.doctype, _doc.name)] = _doc
                return _doc

            doc.append = append
            doc.insert = insert

            def as_dict(_doc=doc):
                return {"name": getattr(_doc, "name", None)}

            doc.as_dict = as_dict
            return doc
        doctype, name = args[0], args[1]
        if isinstance(name, dict):
            found = db_exists(doctype, name)
            if not found:
                raise DoesNotExistError(
                    "{0} not found".format(doctype)
                )
            name = found
        doc = frappe._docs.get((doctype, name))
        if doc is None:
            raise DoesNotExistError(
                "{0} {1} not found".format(doctype, name)
            )
        doc._reload_log = frappe._reloads
        return doc

    frappe.get_doc = get_doc

    def call(method, **kwargs):
        frappe._calls.append((method, kwargs))
        return {"cashback_amount": 0}

    frappe.call = call

    def log_error(title=None, message=None):
        frappe._log_errors.append((title, message))

    frappe.log_error = log_error

    # order.py's `from frappe.model.document import Document` — the
    # stub is registered as a package with in-memory submodules.
    frappe.__path__ = []
    model = types.ModuleType("frappe.model")
    model.__path__ = []
    document = types.ModuleType("frappe.model.document")
    document.Document = _Doc
    model.document = document
    frappe.model = model

    sys.modules["frappe"] = frappe
    sys.modules["frappe.model"] = model
    sys.modules["frappe.model.document"] = document
    return frappe


def _load_order_module():
    with open(os.path.abspath(_MODULE_PATH)) as fh:
        source = fh.read().replace("{app_name}", _STUB_APP)
    module = types.ModuleType("create_order_under_test")
    module.__file__ = os.path.abspath(_MODULE_PATH)
    # No parent package: the optional weather_notice relative import
    # then raises a clean ImportError (caught in order.py) instead of
    # warning while probing __path__.
    module.__package__ = ""
    exec(compile(source, _MODULE_PATH, "exec"), module.__dict__)
    return module


@unittest.skipIf(
    HAVE_REAL_FRAPPE,
    "real frappe importable — run FrappeTestCase suites under bench",
)
class CreateOrderPaymentTestBase(unittest.TestCase):
    USER = "buyer@example.com"

    @classmethod
    def setUpClass(cls):
        cls.frappe = _install_stub_frappe()
        _install_stub_packages()
        cls.order_module = _load_order_module()

    def setUp(self):
        f = self.frappe
        f._docs.clear()
        f._inserted.clear()
        f._singles.clear()
        f._log_errors.clear()
        f._reloads.clear()
        f._calls.clear()
        f.session = types.SimpleNamespace(user=self.USER)
        f._singles["Permission Settings"] = _Doc(
            require_phone_for_order=0, auto_approve_orders=0
        )
        f._docs[("Shop", "SHOP-1")] = _Doc(
            doctype="Shop",
            name="SHOP-1",
            user="seller@example.com",
            auto_approve_orders=0,
        )
        f._docs[("Product", "PROD-1")] = _Doc(
            doctype="Product", name="PROD-1", price=10.0, cost=6.0
        )
        self.recorded = []
        sys.modules.pop(_PAY_MODULE, None)

    def install_pay_module(self, recorder=None):
        """Compose the stub pay wallet payment module in."""

        def create_order_transaction(order_id=None, payment_sys_id=None):
            self.recorded.append(
                {"order_id": order_id, "payment_sys_id": payment_sys_id}
            )
            if recorder is not None:
                return recorder(order_id, payment_sys_id)
            return {"status": "success", "transaction_id": "TXN-0001"}

        mod = types.ModuleType(_PAY_MODULE)
        mod.create_order_transaction = create_order_transaction
        sys.modules[_PAY_MODULE] = mod
        parent = sys.modules[_STUB_APP + ".wallet.tenant.api"]
        parent.payment = mod
        return mod

    def order_data(self, **overrides):
        data = {
            "user": self.USER,
            "shop": "SHOP-1",
            "order_items": [{"product": "PROD-1", "quantity": 2}],
        }
        data.update(overrides)
        return data

    def created_order(self):
        orders = [
            d for d in self.frappe._inserted if d.doctype == "Order"
        ]
        self.assertEqual(len(orders), 1)
        return orders[0]


class TestCreateOrderPaymentWiring(CreateOrderPaymentTestBase):
    def test_payment_id_records_transaction_via_pay_module(self):
        self.install_pay_module()
        self.order_module.create_order(self.order_data(payment_id="Wallet"))
        order = self.created_order()
        self.assertEqual(
            self.recorded,
            [{"order_id": order.name, "payment_sys_id": "Wallet"}],
        )
        # The response is refreshed after the recorder may have flipped
        # the order Paid through its own doc instance.
        self.assertIn(order.name, self.frappe._reloads)
        self.assertEqual(self.frappe._log_errors, [])

    def test_order_without_payment_id_is_untouched(self):
        self.install_pay_module()
        result = self.order_module.create_order(self.order_data())
        self.created_order()
        self.assertEqual(self.recorded, [])
        self.assertEqual(self.frappe._log_errors, [])
        self.assertEqual(result["message"], "Order created successfully.")

    def test_guest_session_skips_recording_with_log(self):
        self.install_pay_module()
        self.frappe.session = types.SimpleNamespace(user="Guest")
        self.order_module.create_order(
            self.order_data(user=None, payment_id="Wallet")
        )
        self.created_order()
        self.assertEqual(self.recorded, [])
        self.assertEqual(len(self.frappe._log_errors), 1)
        self.assertIn("Guest", self.frappe._log_errors[0][1])

    def test_missing_pay_module_logs_and_skips(self):
        # Unmigrated site: pay's wallet module is not composed in. The
        # order is still created; the skip is logged, never silent.
        self.assertNotIn(_PAY_MODULE, sys.modules)
        result = self.order_module.create_order(
            self.order_data(payment_id="Wallet")
        )
        self.created_order()
        self.assertEqual(self.recorded, [])
        self.assertEqual(len(self.frappe._log_errors), 1)
        self.assertIn("not composed", self.frappe._log_errors[0][1])
        self.assertEqual(result["message"], "Order created successfully.")

    def test_recorder_errors_propagate(self):
        # A composed pay module that refuses (e.g. insufficient wallet
        # balance) must fail the request — no unpaid order silently
        # minted, no swallowed error.
        def refuse(order_id, payment_sys_id):
            raise self.frappe.ValidationError("Insufficient Wallet Balance.")

        self.install_pay_module(recorder=refuse)
        with self.assertRaises(self.frappe.ValidationError):
            self.order_module.create_order(
                self.order_data(payment_id="Wallet")
            )
        self.assertEqual(len(self.recorded), 1)

    def test_duplicate_response_from_recorder_is_tolerated(self):
        # create_order_transaction's same order+gateway dedupe returns
        # {"duplicate": True}; order creation completes normally.
        def duplicate(order_id, payment_sys_id):
            return {
                "status": "success",
                "transaction_id": "TXN-OLD",
                "duplicate": True,
            }

        self.install_pay_module(recorder=duplicate)
        result = self.order_module.create_order(
            self.order_data(payment_id="Wallet")
        )
        self.assertEqual(result["message"], "Order created successfully.")

    def test_record_order_payment_helper_requires_payment_id(self):
        self.install_pay_module()
        order = _Doc(doctype="Order", name="ORD-X")
        self.order_module._record_order_payment(order, {})
        self.order_module._record_order_payment(order, {"payment_id": ""})
        self.order_module._record_order_payment(order, None)
        self.assertEqual(self.recorded, [])


if __name__ == "__main__":
    unittest.main()
