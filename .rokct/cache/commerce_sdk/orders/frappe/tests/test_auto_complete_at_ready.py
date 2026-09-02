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

"""Auto-complete at Ready (design strip section 42, chips 799/800),
unit-tested without a bench.

The rule lives on the Order doctype controller
(`doctype/order/order.py::complete_at_ready_if_due`, called from
`before_save`): with `Shop.auto_complete_at_ready` on, an order that
TRANSITIONS into "Ready" is written straight through to "Delivered" —
nobody taps to hand it over. Everything the rule refuses matters as much
as what it does, so each guard gets a case: off by default, pickup only,
a real transition only, never on insert.

The suite skips itself when the real frappe package is importable (a
bench context).

Run standalone:
    python3 -m unittest orders/frappe/tests/test_auto_complete_at_ready.py
"""

import importlib.util
import os
import sys
import types
import unittest

HAVE_REAL_FRAPPE = importlib.util.find_spec("frappe") is not None

_MODULE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..",
    "src",
    "tenant",
    "doctype",
    "order",
    "order.py",
)


class _Doc(types.SimpleNamespace):
    def get(self, key, default=None):
        return getattr(self, key, default)


def _install_stub_frappe():
    frappe = types.ModuleType("frappe")
    frappe._shops = {}

    class ValidationError(Exception):
        pass

    frappe.ValidationError = ValidationError

    def throw(msg, exc=ValidationError):
        raise exc(msg)

    frappe.throw = throw

    def db_get_value(doctype, name, fieldname="name", **kwargs):
        if doctype == "Shop":
            shop = frappe._shops.get(name)
            return None if shop is None else getattr(shop, fieldname, None)
        return None

    frappe.db = types.SimpleNamespace(
        get_value=db_get_value,
        exists=lambda *a, **k: False,
        count=lambda *a, **k: 0,
        get_single_value=lambda *a, **k: 0,
    )
    frappe.get_doc = lambda *a, **k: _Doc(tax=0, percentage=0)

    model = types.ModuleType("frappe.model")
    document = types.ModuleType("frappe.model.document")

    class Document:
        """Just enough of frappe.model.document.Document."""

        def get(self, key, default=None):
            return getattr(self, key, default)

    document.Document = Document
    model.document = document
    frappe.model = model

    sys.modules["frappe"] = frappe
    sys.modules["frappe.model"] = model
    sys.modules["frappe.model.document"] = document
    return frappe


def _load_controller():
    with open(os.path.abspath(_MODULE_PATH)) as fh:
        source = fh.read()
    module = types.ModuleType("order_controller_under_test")
    module.__file__ = os.path.abspath(_MODULE_PATH)
    module.__package__ = ""
    exec(compile(source, _MODULE_PATH, "exec"), module.__dict__)
    return module


@unittest.skipIf(
    HAVE_REAL_FRAPPE,
    "real frappe importable — run FrappeTestCase suites under bench",
)
class AutoCompleteAtReadyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.frappe = _install_stub_frappe()
        cls.controller = _load_controller()

    def setUp(self):
        self.frappe._shops.clear()
        self.frappe._shops["SHOP-1"] = _Doc(
            name="SHOP-1", auto_complete_at_ready=0
        )

    def _order(
        self,
        status="Ready",
        delivery_type="Pickup",
        previous_status="Cooking",
        is_new=False,
        shop="SHOP-1",
    ):
        order = self.controller.Order()
        order.status = status
        order.delivery_type = delivery_type
        order.shop = shop
        order.is_new = lambda: is_new
        previous = (
            None
            if previous_status is None
            else _Doc(status=previous_status)
        )
        order.get_doc_before_save = lambda: previous
        return order

    # --- the rule fires -------------------------------------------------

    def test_ready_pickup_completes_when_the_shop_opted_in(self):
        self.frappe._shops["SHOP-1"].auto_complete_at_ready = 1
        order = self._order()
        order.complete_at_ready_if_due()
        self.assertEqual(order.status, "Delivered")

    def test_lowercase_till_pickup_is_honoured_too(self):
        # The till writes 'pickup'; the customer checkout writes "Pickup".
        self.frappe._shops["SHOP-1"].auto_complete_at_ready = 1
        order = self._order(delivery_type="pickup")
        order.complete_at_ready_if_due()
        self.assertEqual(order.status, "Delivered")

    # --- and everything it refuses --------------------------------------

    def test_off_by_default(self):
        order = self._order()
        order.complete_at_ready_if_due()
        self.assertEqual(order.status, "Ready")

    def test_delivery_orders_are_never_completed(self):
        # settle_order pays the deliveryman the full fee on Delivered:
        # auto-completing a travelling order would pay for a delivery
        # nobody made.
        self.frappe._shops["SHOP-1"].auto_complete_at_ready = 1
        order = self._order(delivery_type="delivery")
        order.complete_at_ready_if_due()
        self.assertEqual(order.status, "Ready")

    def test_an_unrelated_edit_of_an_already_ready_order_does_nothing(self):
        self.frappe._shops["SHOP-1"].auto_complete_at_ready = 1
        order = self._order(previous_status="Ready")
        order.complete_at_ready_if_due()
        self.assertEqual(order.status, "Ready")

    def test_a_new_row_created_at_ready_is_exempt(self):
        # A packed send-for-delivery POS sale is INSERTED holding Ready.
        self.frappe._shops["SHOP-1"].auto_complete_at_ready = 1
        order = self._order(is_new=True, previous_status=None)
        order.complete_at_ready_if_due()
        self.assertEqual(order.status, "Ready")

    def test_other_statuses_pass_through(self):
        self.frappe._shops["SHOP-1"].auto_complete_at_ready = 1
        for status in ("New", "Accepted", "Cooking", "Delivered", "Cancelled"):
            order = self._order(status=status)
            order.complete_at_ready_if_due()
            self.assertEqual(order.status, status)

    def test_a_shopless_order_is_left_alone(self):
        order = self._order(shop=None)
        order.complete_at_ready_if_due()
        self.assertEqual(order.status, "Ready")

    # --- and it is actually wired into the save path ---------------------

    def test_before_save_runs_the_rule(self):
        self.frappe._shops["SHOP-1"].auto_complete_at_ready = 1
        order = self._order()
        order.order_items = []
        order.coupon_code = None
        order.delivery_fee = 0
        order.before_save()
        self.assertEqual(order.status, "Delivered")


if __name__ == "__main__":
    unittest.main()
