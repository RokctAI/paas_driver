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

"""settle_delivery_callout — the driver's callout when the customer
collected a delivery order in person (design strip section 43, flag b),
unit-tested without a bench.

Rides the same in-memory ``frappe`` stub as test_settlement.py, whose
base class it reuses, so the callout's money is measured against the
same wallet ledger the ordinary settlement writes into. The end-to-end
ordering (callout and unassign BEFORE Delivered) is pinned separately in
merchants/frappe/tests/test_collect_in_person.py.

Run standalone:
    python3 -m unittest orders/frappe/tests/test_collect_callout.py
"""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from test_settlement import SettlementTestBase  # noqa: E402


class TestSettleDeliveryCallout(SettlementTestBase):
    def setUp(self):
        super().setUp()
        self.frappe._meta_fields["Order"] = {"settled", "callout_settled"}
        self.order.status = "Ready"
        self.order.callout_settled = 0

    def callout(self):
        return self.settlement.settle_delivery_callout(self.order)

    def test_driver_is_credited_the_gross_fee(self):
        result = self.callout()

        self.assertTrue(result["settled"])
        self.assertEqual(result["delivery_fee_credit"], 10.0)
        self.assertEqual(self.wallet_balance("driver@example.com"), 10.0)
        rows = self.history_rows("driver@example.com")
        self.assertEqual(len(rows), 1)
        self.assertIn("collected in person", rows[0].description)

    def test_the_flag_is_written_so_a_replay_moves_nothing(self):
        self.callout()
        self.assertEqual(self.order.callout_settled, 1)

        again = self.callout()

        self.assertFalse(again["settled"])
        self.assertEqual(again["reason"], "already-settled")
        self.assertEqual(self.wallet_balance("driver@example.com"), 10.0)

    def test_no_driver_pays_nobody(self):
        self.order.deliveryman = None
        result = self.callout()
        self.assertEqual(result["reason"], "no-driver")
        self.assertEqual(self.history_rows(), [])

    def test_a_zero_fee_pays_nobody(self):
        self.order.delivery_fee = 0
        result = self.callout()
        self.assertEqual(result["reason"], "no-fee")
        self.assertEqual(self.history_rows(), [])

    def test_an_unmigrated_site_refuses_to_move_money(self):
        self.frappe._meta_fields["Order"] = {"settled"}
        result = self.callout()
        self.assertEqual(result["reason"], "callout-settled-field-missing")
        self.assertEqual(self.history_rows(), [])

    def test_a_credit_settled_order_pays_nobody_again(self):
        self.frappe._meta_fields["Order"] = {
            "settled", "callout_settled", "credit_settled",
        }
        self.order.credit_settled = 1
        result = self.callout()
        self.assertEqual(result["reason"], "credit-settled")
        self.assertEqual(self.history_rows(), [])

    def test_delivery_commission_is_billed_back(self):
        self.enable_commission_settings(delivery=20.0)
        result = self.callout()

        self.assertEqual(result["delivery_commission"], 2.0)
        self.assertEqual(self.wallet_balance("driver@example.com"), 8.0)
        rows = [
            r for r in self.commission_rows()
            if r.commission_type == "Delivery"
        ]
        self.assertEqual(len(rows), 1)
        self.assertEqual(float(rows[0].base_amount), 10.0)
        self.assertEqual(float(rows[0].rate), 20.0)

    def test_no_commission_row_when_nothing_is_billed(self):
        self.callout()
        self.assertEqual(self.commission_rows(), [])

    def test_the_row_lock_is_taken_on_the_order(self):
        self.callout()
        self.assertIn(("Order", "ORD-1"), self.frappe._locks)


if __name__ == "__main__":
    unittest.main()
