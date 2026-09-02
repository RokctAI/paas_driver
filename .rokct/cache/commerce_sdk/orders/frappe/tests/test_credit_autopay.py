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

"""auto_pay_credit_orders, unit-tested without a bench.

Mirrors tests/test_settlement.py (which itself mirrors pay's
wallet/frappe/tests/test_create_order_transaction.py): the settlement
module is loaded by file path over a minimal in-memory ``frappe`` stub,
and the suite skips itself when the real frappe package is importable
(a bench context, where FrappeTestCase suites are the right tool).

Run standalone:
    python3 -m unittest orders/frappe/tests/test_credit_autopay.py
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
    "..", "src", "tenant", "api", "order", "settlement.py",
)


class _AttrDict(dict):
    def __getattr__(self, key):
        try:
            return self[key]
        except KeyError:
            return None


class _Doc(types.SimpleNamespace):
    """Just enough of frappe.model.document.Document."""

    def get(self, key, default=None):
        return getattr(self, key, default)

    def save(self, ignore_permissions=False):
        saves = getattr(self, "_save_log", None)
        if saves is not None:
            saves.append((self.doctype, self.name))
        return self


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
    frappe.utils = types.SimpleNamespace(
        now_datetime=lambda: datetime(2026, 8, 28, 12, 0, 0)
    )
    frappe.flags = types.SimpleNamespace()

    # Test-controlled storage.
    frappe._docs = {}  # (doctype, name) -> _Doc
    frappe._inserted = []  # docs created via get_doc({...}).insert()
    frappe._locks = []  # (doctype, name) for every for_update access
    frappe._meta_fields = {}  # doctype -> set of extra known fields
    frappe._set_values = []  # (doctype, name, {field: value})
    frappe._saves = []  # (doctype, name) for every doc.save()

    def _matches(doc, filters):
        for key, wanted in (filters or {}).items():
            have = getattr(doc, key, None)
            if (
                isinstance(wanted, (list, tuple))
                and len(wanted) == 2
                and wanted[0] == "!="
            ):
                if have == wanted[1]:
                    return False
            elif have != wanted:
                return False
        return True

    def _find_by_filters(doctype, filters):
        for (dt, _name), doc in sorted(frappe._docs.items()):
            if dt == doctype and _matches(doc, filters):
                return doc
        return None

    def get_value(
        doctype,
        filters,
        fieldname="name",
        as_dict=False,
        for_update=False,
        **kwargs,
    ):
        if isinstance(filters, dict):
            doc = _find_by_filters(doctype, filters)
        else:
            doc = frappe._docs.get((doctype, filters))
        if doc is None:
            return None
        if for_update:
            frappe._locks.append((doctype, doc.name))
        if isinstance(fieldname, (list, tuple)):
            if as_dict:
                return _AttrDict(
                    {f: getattr(doc, f, None) for f in fieldname}
                )
            return tuple(getattr(doc, f, None) for f in fieldname)
        return getattr(doc, fieldname, None)

    def set_value(doctype, name, field, value=None, **kwargs):
        doc = frappe._docs.get((doctype, name))
        if doc is None:
            raise DoesNotExistError(f"{doctype} {name} not found")
        updates = field if isinstance(field, dict) else {field: value}
        for key, val in updates.items():
            setattr(doc, key, val)
        frappe._set_values.append((doctype, name, dict(updates)))

    def exists(doctype, name):
        return name if (doctype, name) in frappe._docs else None

    frappe.db = types.SimpleNamespace(
        get_value=get_value, set_value=set_value, exists=exists
    )

    def get_all(doctype, filters=None, fields=None, order_by=None, **kw):
        docs = [
            doc
            for (dt, _name), doc in sorted(frappe._docs.items())
            if dt == doctype and _matches(doc, filters)
        ]
        if order_by == "creation asc":
            docs.sort(key=lambda d: getattr(d, "creation", None) or "")
        return [
            _AttrDict(
                {f: getattr(doc, f, None) for f in (fields or ["name"])}
            )
            for doc in docs
        ]

    frappe.get_all = get_all

    def get_doc(*args, **kwargs):
        if len(args) == 1 and isinstance(args[0], dict):
            fields = dict(args[0])
            doc = _Doc(**fields)

            def insert(ignore_permissions=False, _doc=doc):
                _doc.name = "{0}-{1:04d}".format(
                    _doc.doctype, len(frappe._inserted) + 1
                )
                frappe._inserted.append(_doc)
                frappe._docs[(_doc.doctype, _doc.name)] = _doc
                return _doc

            doc.insert = insert
            return doc
        doctype, name = args[0], args[1]
        for_update = kwargs.get("for_update") or (
            len(args) > 2 and args[2]
        )
        doc = frappe._docs.get((doctype, name))
        if doc is None:
            raise DoesNotExistError(f"{doctype} {name} not found")
        if for_update:
            frappe._locks.append((doctype, name))
        doc._save_log = frappe._saves
        return doc

    frappe.get_doc = get_doc

    def get_meta(doctype):
        known = frappe._meta_fields.get(doctype, set())
        return types.SimpleNamespace(
            has_field=lambda fieldname: fieldname in known
        )

    frappe.get_meta = get_meta

    sys.modules["frappe"] = frappe
    return frappe


@unittest.skipIf(
    HAVE_REAL_FRAPPE,
    "real frappe importable — run FrappeTestCase suites under bench",
)
class AutoPayTestBase(unittest.TestCase):
    USER = "buyer@example.com"

    @classmethod
    def setUpClass(cls):
        cls.frappe = _install_stub_frappe()
        spec = importlib.util.spec_from_file_location(
            "credit_autopay_under_test", _MODULE_PATH
        )
        cls.settlement = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.settlement)

    def setUp(self):
        f = self.frappe
        f._docs.clear()
        f._inserted.clear()
        f._locks.clear()
        f._set_values.clear()
        f._meta_fields.clear()
        f._saves.clear()
        f.flags = types.SimpleNamespace()
        f._meta_fields["Order"] = {"settled"}
        f._meta_fields["User"] = set()

    # -- helpers ----------------------------------------------------------

    def add_order(self, name, total, creation, payment_status="Credit",
                  status="Shipped", user=None):
        doc = _Doc(
            doctype="Order",
            name=name,
            user=user or self.USER,
            shop="SHOP-1",
            status=status,
            payment_status=payment_status,
            total_price=total,
            creation=creation,
            settled=0,
        )
        self.frappe._docs[("Order", name)] = doc
        return doc

    def set_wallet(self, user, balance):
        name = "WAL-" + user
        doc = _Doc(
            doctype="Wallet", name=name, user=user, balance=balance
        )
        self.frappe._docs[("Wallet", name)] = doc
        return doc

    def wallet_balance(self, user):
        for (dt, _name), doc in self.frappe._docs.items():
            if dt == "Wallet" and doc.user == user:
                return float(doc.balance or 0)
        return None

    def history_rows(self):
        return [
            d
            for d in self.frappe._inserted
            if d.doctype == "Wallet History"
        ]

    def payment_status(self, name):
        return self.frappe._docs[("Order", name)].payment_status

    def minted_transactions(self):
        return [
            d
            for d in self.frappe._inserted
            if d.doctype == "Transaction"
        ]


class TestAutoPayCreditOrders(AutoPayTestBase):
    def test_pays_oldest_first_while_balance_covers(self):
        self.add_order("ORD-A", 50.0, "2026-08-01")
        self.add_order("ORD-B", 30.0, "2026-08-02")
        self.add_order("ORD-C", 10.0, "2026-08-03")
        self.set_wallet(self.USER, 60.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        # A (50) paid, balance 10; B (30) unaffordable -> strict FIFO
        # stops, so C (10) is NOT paid even though it would fit.
        self.assertEqual(result["orders_paid"], ["ORD-A"])
        self.assertEqual(result["amount_paid"], 50.0)
        self.assertEqual(self.payment_status("ORD-A"), "Paid")
        self.assertEqual(self.payment_status("ORD-B"), "Credit")
        self.assertEqual(self.payment_status("ORD-C"), "Credit")
        self.assertEqual(self.wallet_balance(self.USER), 10.0)

    def test_pays_multiple_orders_in_creation_order(self):
        self.add_order("ORD-B", 30.0, "2026-08-02")
        self.add_order("ORD-A", 50.0, "2026-08-01")
        self.set_wallet(self.USER, 80.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], ["ORD-A", "ORD-B"])
        self.assertEqual(self.wallet_balance(self.USER), 0.0)

    def test_never_overdraws(self):
        self.add_order("ORD-A", 100.0, "2026-08-01")
        self.set_wallet(self.USER, 99.99)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], [])
        self.assertEqual(self.payment_status("ORD-A"), "Credit")
        self.assertEqual(self.wallet_balance(self.USER), 99.99)
        self.assertEqual(self.history_rows(), [])

    def test_negative_balance_pays_nothing(self):
        self.add_order("ORD-A", 10.0, "2026-08-01")
        self.set_wallet(self.USER, -5.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], [])
        self.assertEqual(self.wallet_balance(self.USER), -5.0)

    def test_exact_balance_pays_in_full(self):
        self.add_order("ORD-A", 75.0, "2026-08-01")
        self.set_wallet(self.USER, 75.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], ["ORD-A"])
        self.assertEqual(self.wallet_balance(self.USER), 0.0)

    def test_full_amount_only_no_partial_debit(self):
        self.add_order("ORD-A", 100.0, "2026-08-01")
        self.set_wallet(self.USER, 40.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        # No partial payment: the balance is untouched.
        self.assertEqual(self.wallet_balance(self.USER), 40.0)
        self.assertEqual(self.history_rows(), [])

    def test_only_credit_orders_of_this_user_are_touched(self):
        self.add_order("ORD-PEND", 10.0, "2026-08-01",
                       payment_status="Pending")
        self.add_order("ORD-PAID", 10.0, "2026-08-02",
                       payment_status="Paid")
        self.add_order("ORD-OTHER", 10.0, "2026-08-03",
                       user="other@example.com")
        self.set_wallet(self.USER, 1000.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], [])
        self.assertEqual(self.wallet_balance(self.USER), 1000.0)
        self.assertEqual(self.payment_status("ORD-OTHER"), "Credit")

    def test_history_row_and_flip_via_doc_save(self):
        self.add_order("ORD-A", 50.0, "2026-08-01")
        self.set_wallet(self.USER, 50.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        rows = self.history_rows()
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].transaction_type, "Payment")
        self.assertEqual(rows[0].amount, -50.0)
        self.assertEqual(rows[0].status, "Paid")
        # The Paid flip went through doc.save (so Order.on_update — and
        # with it the settlement hook — fires on a real site).
        self.assertIn(("Order", "ORD-A"), self.frappe._saves)

    def test_legacy_user_balance_mirror_is_shifted(self):
        f = self.frappe
        f._meta_fields["User"] = {"wallet_balance"}
        f._docs[("User", self.USER)] = _Doc(
            name=self.USER, wallet_balance=50.0
        )
        self.add_order("ORD-A", 50.0, "2026-08-01")
        self.set_wallet(self.USER, 50.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(
            f._docs[("User", self.USER)].wallet_balance, 0.0
        )

    def test_reentrant_call_is_skipped(self):
        self.add_order("ORD-A", 10.0, "2026-08-01")
        self.set_wallet(self.USER, 100.0)
        self.frappe.flags.rokct_credit_auto_pay_running = True
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], [])
        self.assertEqual(result["reason"], "re-entrant-call-skipped")
        self.assertEqual(self.wallet_balance(self.USER), 100.0)

    def test_flag_cleared_after_run(self):
        self.add_order("ORD-A", 10.0, "2026-08-01")
        self.set_wallet(self.USER, 100.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        self.assertFalse(
            self.frappe.flags.rokct_credit_auto_pay_running
        )

    def test_no_user_is_a_noop(self):
        result = self.settlement.auto_pay_credit_orders(None)
        self.assertEqual(result["orders_paid"], [])

    def test_zero_total_credit_order_flips_without_debit(self):
        self.add_order("ORD-Z", 0.0, "2026-08-01")
        self.set_wallet(self.USER, 5.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], ["ORD-Z"])
        self.assertEqual(self.payment_status("ORD-Z"), "Paid")
        self.assertEqual(self.wallet_balance(self.USER), 5.0)
        self.assertEqual(self.history_rows(), [])

    def test_raced_order_reread_under_lock_is_skipped_not_paid_twice(self):
        # get_all returns a stale candidate list; the under-lock re-read
        # must skip an order no longer "Credit" instead of debiting it.
        self.add_order("ORD-A", 30.0, "2026-08-01")
        self.add_order("ORD-B", 30.0, "2026-08-02")
        self.set_wallet(self.USER, 60.0)
        real_get_all = self.frappe.get_all

        def stale_get_all(doctype, *args, **kwargs):
            rows = real_get_all(doctype, *args, **kwargs)
            if doctype == "Order":
                # Simulate a concurrent payer flipping ORD-A after the
                # candidate list was read.
                self.frappe._docs[
                    ("Order", "ORD-A")
                ].payment_status = "Paid"
            return rows

        self.frappe.get_all = stale_get_all
        try:
            result = self.settlement.auto_pay_credit_orders(self.USER)
        finally:
            self.frappe.get_all = real_get_all
        self.assertEqual(result["orders_paid"], ["ORD-B"])
        self.assertEqual(self.wallet_balance(self.USER), 30.0)

    def test_open_cash_transaction_is_canceled_on_auto_pay(self):
        f = self.frappe
        f._docs[("PaaS Payment Gateway", "Cash")] = _Doc(
            name="Cash", gateway_controller="Cash"
        )
        f._docs[("Transaction", "TXN-CASH")] = _Doc(
            doctype="Transaction",
            name="TXN-CASH",
            payable_type="Order",
            payable_id="ORD-A",
            payment_gateway="Cash",
            status="Pending",
        )
        f._docs[("Transaction", "TXN-PAID")] = _Doc(
            doctype="Transaction",
            name="TXN-PAID",
            payable_type="Order",
            payable_id="ORD-OTHER",
            payment_gateway="Cash",
            status="Paid",
        )
        self.add_order("ORD-A", 50.0, "2026-08-01")
        self.set_wallet(self.USER, 50.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(
            f._docs[("Transaction", "TXN-CASH")].status, "Canceled"
        )
        self.assertEqual(
            f._docs[("Transaction", "TXN-PAID")].status, "Paid"
        )

    def test_auto_pay_mints_paid_wallet_transaction(self):
        # The sweep must leave a payment record on the books: one Paid
        # Transaction per debited order, shaped like pay's
        # create_order_transaction wallet recording.
        f = self.frappe
        f._docs[("PaaS Payment Gateway", "Wallet")] = _Doc(
            name="Wallet", gateway_controller="Wallet"
        )
        self.add_order("ORD-A", 50.0, "2026-08-01")
        self.set_wallet(self.USER, 50.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        txns = self.minted_transactions()
        self.assertEqual(len(txns), 1)
        txn = txns[0]
        self.assertEqual(txn.payable_type, "Order")
        self.assertEqual(txn.payable_id, "ORD-A")
        self.assertEqual(txn.status, "Paid")
        self.assertEqual(txn.user, self.USER)
        self.assertEqual(txn.amount, 50.0)
        self.assertEqual(txn.type, "model")
        self.assertEqual(txn.payment_gateway, "Wallet")
        self.assertIsNotNone(txn.performed_at)

    def test_mint_without_wallet_gateway_omits_gateway_link(self):
        # No PaaS Payment Gateway with a "wallet" controller configured:
        # the Transaction is still minted, just without a gateway link
        # (create_order_transaction's unknown-gateway behavior).
        self.add_order("ORD-A", 25.0, "2026-08-01")
        self.set_wallet(self.USER, 25.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        txns = self.minted_transactions()
        self.assertEqual(len(txns), 1)
        self.assertEqual(txns[0].status, "Paid")
        self.assertIsNone(getattr(txns[0], "payment_gateway", None))

    def test_mint_matches_wallet_gateway_case_insensitively(self):
        f = self.frappe
        f._docs[("PaaS Payment Gateway", "My Wallet GW")] = _Doc(
            name="My Wallet GW", gateway_controller="  WALLET "
        )
        self.add_order("ORD-A", 10.0, "2026-08-01")
        self.set_wallet(self.USER, 10.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(
            self.minted_transactions()[0].payment_gateway, "My Wallet GW"
        )

    def test_mint_skipped_when_paid_transaction_already_exists(self):
        # pay#40's cross-gateway guard semantics: an order already
        # carrying a Paid Transaction is never double-recorded.
        f = self.frappe
        f._docs[("Transaction", "TXN-PRE")] = _Doc(
            doctype="Transaction",
            name="TXN-PRE",
            payable_type="Order",
            payable_id="ORD-A",
            status="Paid",
        )
        self.add_order("ORD-A", 50.0, "2026-08-01")
        self.set_wallet(self.USER, 50.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        # The sweep still pays and flips the order as before...
        self.assertEqual(result["orders_paid"], ["ORD-A"])
        self.assertEqual(self.payment_status("ORD-A"), "Paid")
        # ...but no second Transaction row is inserted.
        self.assertEqual(self.minted_transactions(), [])

    def test_mint_ignores_canceled_and_pending_transactions(self):
        # A Canceled/Pending row is not a payment record — the Paid
        # wallet Transaction is still minted alongside it.
        f = self.frappe
        f._docs[("Transaction", "TXN-OPEN")] = _Doc(
            doctype="Transaction",
            name="TXN-OPEN",
            payable_type="Order",
            payable_id="ORD-A",
            status="Pending",
        )
        self.add_order("ORD-A", 50.0, "2026-08-01")
        self.set_wallet(self.USER, 50.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(len(self.minted_transactions()), 1)
        # The open row was superseded and canceled by the sweep.
        self.assertEqual(
            f._docs[("Transaction", "TXN-OPEN")].status, "Canceled"
        )

    def test_no_transaction_minted_for_zero_total_order(self):
        self.add_order("ORD-Z", 0.0, "2026-08-01")
        self.set_wallet(self.USER, 5.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(self.minted_transactions(), [])

    def test_one_transaction_per_order_in_multi_order_sweep(self):
        self.add_order("ORD-A", 30.0, "2026-08-01")
        self.add_order("ORD-B", 20.0, "2026-08-02")
        self.set_wallet(self.USER, 50.0)
        self.settlement.auto_pay_credit_orders(self.USER)
        txns = self.minted_transactions()
        self.assertEqual(
            sorted(t.payable_id for t in txns), ["ORD-A", "ORD-B"]
        )
        self.assertEqual([t.status for t in txns], ["Paid", "Paid"])

    def test_settlement_ignores_canceled_cash_transaction(self):
        # The COD gross debit must not fire for a credit order that was
        # wallet auto-paid: its stale cash Transaction is Canceled and
        # the deliveryman never kept the cash.
        f = self.frappe
        f._docs[("Shop", "SHOP-1")] = _Doc(
            name="SHOP-1", user="seller@example.com", percentage=10.0
        )
        f._docs[("PaaS Payment Gateway", "Cash")] = _Doc(
            name="Cash", gateway_controller="Cash"
        )
        f._docs[("Transaction", "TXN-CASH")] = _Doc(
            doctype="Transaction",
            name="TXN-CASH",
            payable_type="Order",
            payable_id="ORD-A",
            payment_gateway="Cash",
            status="Canceled",
        )
        order = self.add_order(
            "ORD-A", 100.0, "2026-08-01",
            payment_status="Paid", status="Delivered",
        )
        order.delivery_fee = 10.0
        order.service_fee = 5.0
        order.deliveryman = "driver@example.com"
        order.cod_collected_amount = 0
        result = self.settlement.settle_order(order)
        self.assertTrue(result["settled"])
        # Delivery fee only — no gross COD debit.
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 10.0
        )


class TestAutoPayPartlyPaidPos(AutoPayTestBase):
    """The POS partly-paid contract: `pos_paid_amount` reduces the credit
    balance the sweep collects — full-amounts-only semantics apply to the
    OUTSTANDING remainder, never the original total."""

    def _enable_pos_paid_field(self):
        self.frappe._meta_fields["Order"] = {"settled", "pos_paid_amount"}

    def test_sweeps_only_the_outstanding_remainder(self):
        self._enable_pos_paid_field()
        order = self.add_order("ORD-A", 325.88, "2026-08-01")
        order.pos_paid_amount = 200.0
        self.set_wallet(self.USER, 130.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], ["ORD-A"])
        self.assertAlmostEqual(result["amount_paid"], 125.88)
        self.assertEqual(self.payment_status("ORD-A"), "Paid")
        self.assertAlmostEqual(self.wallet_balance(self.USER), 4.12)
        minted = self.minted_transactions()
        self.assertEqual(len(minted), 1)
        self.assertAlmostEqual(minted[0].amount, 125.88)

    def test_fifo_gate_uses_the_remainder_not_the_total(self):
        self._enable_pos_paid_field()
        order = self.add_order("ORD-A", 100.0, "2026-08-01")
        order.pos_paid_amount = 60.0
        self.set_wallet(self.USER, 50.0)
        # Balance 50 covers the 40 remainder even though it never covers
        # the 100 total.
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], ["ORD-A"])
        self.assertAlmostEqual(self.wallet_balance(self.USER), 10.0)

    def test_fully_till_paid_credit_order_flips_without_debit(self):
        self._enable_pos_paid_field()
        order = self.add_order("ORD-A", 80.0, "2026-08-01")
        order.pos_paid_amount = 80.0
        self.set_wallet(self.USER, 5.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], ["ORD-A"])
        self.assertEqual(result["amount_paid"], 0.0)
        self.assertEqual(self.payment_status("ORD-A"), "Paid")
        self.assertEqual(self.wallet_balance(self.USER), 5.0)
        self.assertEqual(self.minted_transactions(), [])

    def test_unmigrated_site_ignores_pos_paid_amount(self):
        # No pos_paid_amount in meta: the sweep keeps full-total behavior
        # even if a stray value sits on the row.
        order = self.add_order("ORD-A", 100.0, "2026-08-01")
        order.pos_paid_amount = 60.0
        self.set_wallet(self.USER, 50.0)
        result = self.settlement.auto_pay_credit_orders(self.USER)
        self.assertEqual(result["orders_paid"], [])
        self.assertEqual(self.payment_status("ORD-A"), "Credit")
        self.assertEqual(self.wallet_balance(self.USER), 50.0)

    def test_credit_settled_repayment_passes_on_the_remainder(self):
        # settle_order on a credit-settled partly-paid POS order credits
        # the shop total - pos_paid (the shop already holds the till
        # cash), not the full total.
        self._enable_pos_paid_field()
        self.frappe._meta_fields["Order"].add("credit_settled")
        self.frappe._docs[("Shop", "SHOP-1")] = _Doc(
            doctype="Shop",
            name="SHOP-1",
            user="owner@example.com",
            percentage=0,
        )
        self.set_wallet("owner@example.com", 0.0)
        order = self.add_order(
            "ORD-A", 325.88, "2026-08-01",
            payment_status="Paid", status="Delivered",
        )
        order.pos_paid_amount = 200.0
        order.credit_settled = 1
        order.delivery_fee = 0.0
        order.service_fee = 0.0
        result = self.settlement.settle_order(order)
        self.assertTrue(result["settled"])
        self.assertAlmostEqual(
            self.wallet_balance("owner@example.com"), 125.88
        )


if __name__ == "__main__":
    unittest.main()
