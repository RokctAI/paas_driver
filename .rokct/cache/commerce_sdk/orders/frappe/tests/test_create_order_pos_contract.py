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

"""create_order's seller-origin (POS) contract, unit-tested without a
bench: the optional initial ``status`` (honored only for seller
sessions, validated against the real status whitelist, legacy dart wire
strings aliased), and the credit / partly-paid recording
(``payment_status: "Credit"`` + ``paid_now`` — Order.pos_paid_amount,
the Paid till Transaction row, the fully-paid flip, and the refusals).

Reuses test_create_order_payment.py's stub harness via a namespaced
import (its TestCase classes are NOT re-collected here). The suite
skips itself when the real frappe package is importable (a bench
context).

Run standalone:
    python3 -m unittest orders/frappe/tests/test_create_order_pos_contract.py
"""

import importlib.util
import sys
import types
import unittest

HAVE_REAL_FRAPPE = importlib.util.find_spec("frappe") is not None

if not HAVE_REAL_FRAPPE:
    sys.path.insert(0, __file__.rsplit("/", 1)[0])
    import test_create_order_payment as harness

SELLER = "seller@example.com"
BUYER = "buyer@example.com"


@unittest.skipIf(
    HAVE_REAL_FRAPPE,
    "real frappe importable — run FrappeTestCase suites under bench",
)
class PosContractTestBase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.frappe = harness._install_stub_frappe()
        harness._install_stub_packages()
        cls.order_module = harness._load_order_module()

    def setUp(self):
        f = self.frappe
        f._docs.clear()
        f._inserted.clear()
        f._singles.clear()
        f._log_errors.clear()
        f._reloads.clear()
        f._calls.clear()
        f.session = types.SimpleNamespace(user=SELLER)
        f.get_roles = lambda user=None: []
        f._singles["Permission Settings"] = harness._Doc(
            require_phone_for_order=0, auto_approve_orders=0
        )
        f._docs[("Shop", "SHOP-1")] = harness._Doc(
            doctype="Shop",
            name="SHOP-1",
            user=SELLER,
            auto_approve_orders=0,
        )
        f._docs[("Product", "PROD-1")] = harness._Doc(
            doctype="Product", name="PROD-1", price=10.0, cost=6.0
        )
        sys.modules.pop(harness._PAY_MODULE, None)

    # -- helpers ----------------------------------------------------------

    def create(self, **extra):
        order_data = {
            "shop": "SHOP-1",
            "user": BUYER,
            "delivery_type": "pickup",
            "order_items": [{"product": "PROD-1", "quantity": 2}],
        }
        order_data.update(extra)
        return self.order_module.create_order(order_data)

    def created_order(self):
        orders = [
            d for d in self.frappe._inserted if d.doctype == "Order"
        ]
        self.assertEqual(len(orders), 1)
        return orders[0]

    def minted_transactions(self):
        return [
            d
            for d in self.frappe._inserted
            if d.doctype == "Transaction"
        ]


class TestSellerOriginInitialStatus(PosContractTestBase):
    def test_seller_supplied_status_is_honored(self):
        self.create(status="Delivered")
        self.assertEqual(self.created_order().status, "Delivered")

    def test_legacy_wire_statuses_are_aliased(self):
        for wire, expected in (
            ("ready", "Ready"),
            ("on_a_way", "Shipped"),
            ("delivered", "Delivered"),
            ("canceled", "Cancelled"),
        ):
            self.setUp()
            self.create(status=wire)
            self.assertEqual(self.created_order().status, expected)

    def test_invalid_status_is_refused(self):
        with self.assertRaises(Exception):
            self.create(status="Sideways")

    def test_customer_session_status_is_ignored(self):
        self.frappe.session = types.SimpleNamespace(user=BUYER)
        self.create(status="Delivered")
        self.assertEqual(self.created_order().status, "New")

    def test_no_status_keeps_the_forced_initial(self):
        self.create()
        self.assertEqual(self.created_order().status, "New")


class TestPosCreditAndPartlyPaid(PosContractTestBase):
    def test_partly_paid_credit_sale(self):
        # 2 x 10.00 = 20.00 total; 12.00 collected at the till.
        self.create(payment_status="Credit", paid_now=12.0)
        order = self.created_order()
        self.assertEqual(order.payment_status, "Credit")
        self.assertEqual(order.pos_paid_amount, 12.0)
        minted = self.minted_transactions()
        self.assertEqual(len(minted), 1)
        self.assertEqual(minted[0].amount, 12.0)
        self.assertEqual(minted[0].status, "Paid")
        self.assertEqual(minted[0].payable_id, order.name)
        self.assertEqual(minted[0].user, BUYER)

    def test_all_on_credit_mints_no_transaction(self):
        self.create(payment_status="Credit")
        order = self.created_order()
        self.assertEqual(order.payment_status, "Credit")
        self.assertEqual(order.pos_paid_amount, 0.0)
        self.assertEqual(self.minted_transactions(), [])

    def test_fully_paid_till_sale_flips_paid(self):
        self.create(paid_now=20.0)
        order = self.created_order()
        self.assertEqual(order.payment_status, "Paid")
        minted = self.minted_transactions()
        self.assertEqual(len(minted), 1)
        self.assertEqual(minted[0].amount, 20.0)

    def test_overpaid_amount_is_capped_at_the_total(self):
        self.create(paid_now=25.0)
        self.assertEqual(self.minted_transactions()[0].amount, 20.0)

    def test_underpaid_without_credit_is_refused(self):
        with self.assertRaises(Exception):
            self.create(paid_now=12.0)

    def test_negative_paid_now_is_refused(self):
        with self.assertRaises(Exception):
            self.create(payment_status="Credit", paid_now=-1.0)

    def test_non_credit_payment_status_is_refused(self):
        with self.assertRaises(Exception):
            self.create(payment_status="Paid")

    def test_customer_session_cannot_use_the_pos_contract(self):
        self.frappe.session = types.SimpleNamespace(user=BUYER)
        with self.assertRaises(Exception):
            self.create(payment_status="Credit")

    def test_payment_id_path_owns_the_recording(self):
        # A gateway payment (payment_id) is _record_order_payment's job;
        # the POS recording must not double-book. The pay module is not
        # composed here, so recording is logged-and-skipped — and no POS
        # Transaction row may appear either.
        self.create(payment_id="GATEWAY-1", paid_now=20.0)
        self.assertEqual(self.minted_transactions(), [])

    def test_plain_order_is_untouched(self):
        self.create()
        order = self.created_order()
        self.assertFalse(getattr(order, "pos_paid_amount", None))
        self.assertEqual(self.minted_transactions(), [])


if __name__ == "__main__":
    unittest.main()
