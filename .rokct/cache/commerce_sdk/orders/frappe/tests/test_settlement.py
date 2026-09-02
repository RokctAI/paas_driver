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

"""settle_order / apply_refund_clawback, unit-tested without a bench.

Mirrors pay's wallet/frappe/tests/test_create_order_transaction.py: the
module under test is loaded by file path over a minimal in-memory
``frappe`` stub, and the suite skips itself when the real frappe
package is importable (a bench context, where FrappeTestCase suites are
the right tool).

Run standalone:
    python3 -m unittest orders/frappe/tests/test_settlement.py
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

    # Test-controlled storage.
    frappe._docs = {}  # (doctype, name) -> _Doc
    frappe._inserted = []  # docs created via get_doc({...}).insert()
    frappe._locks = []  # (doctype, name) for every for_update access
    frappe._meta_fields = {}  # doctype -> set of extra known fields
    frappe._set_values = []  # (doctype, name, {field: value})

    def _find_by_filters(doctype, filters):
        for (dt, _name), doc in sorted(frappe._docs.items()):
            if dt != doctype:
                continue
            ok = True
            for key, wanted in filters.items():
                have = getattr(doc, key, None)
                if (
                    isinstance(wanted, (list, tuple))
                    and len(wanted) == 2
                    and wanted[0] == "!="
                ):
                    ok = ok and have != wanted[1]
                else:
                    ok = ok and have == wanted
            if ok:
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

    def get_single_value(doctype, fieldname):
        doc = frappe._docs.get((doctype, doctype))
        if doc is None:
            return None
        return getattr(doc, fieldname, None)

    frappe.db = types.SimpleNamespace(
        get_value=get_value,
        set_value=set_value,
        exists=exists,
        get_single_value=get_single_value,
    )

    def get_all(doctype, filters=None, fields=None, **kwargs):
        rows = []
        for (dt, _name), doc in sorted(frappe._docs.items()):
            if dt != doctype:
                continue
            ok = True
            for key, wanted in (filters or {}).items():
                have = getattr(doc, key, None)
                if (
                    isinstance(wanted, (list, tuple))
                    and len(wanted) == 2
                    and wanted[0] == "!="
                ):
                    ok = ok and have != wanted[1]
                else:
                    ok = ok and have == wanted
            if ok:
                rows.append(
                    _AttrDict(
                        {
                            f: getattr(doc, f, None)
                            for f in (fields or ["name"])
                        }
                    )
                )
        return rows

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
class SettlementTestBase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.frappe = _install_stub_frappe()
        spec = importlib.util.spec_from_file_location(
            "order_settlement_under_test", _MODULE_PATH
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
        f._meta_fields["Order"] = {"settled"}
        f._meta_fields["Order Refund"] = {"clawback_settled"}
        f._meta_fields["User"] = set()

        f._docs[("Shop", "SHOP-1")] = _Doc(
            name="SHOP-1", user="seller@example.com", percentage=10.0
        )
        self.order = _Doc(
            doctype="Order",
            name="ORD-1",
            user="buyer@example.com",
            shop="SHOP-1",
            status="Delivered",
            payment_status="Paid",
            total_price=100.0,
            delivery_fee=10.0,
            service_fee=5.0,
            deliveryman="driver@example.com",
            cod_collected_amount=0,
            settled=0,
        )
        f._docs[("Order", "ORD-1")] = self.order

    # -- helpers ----------------------------------------------------------

    def wallet_balance(self, user):
        for (dt, _name), doc in self.frappe._docs.items():
            if dt == "Wallet" and doc.user == user:
                return float(doc.balance or 0)
        return None

    def history_rows(self, user=None):
        wallets = {
            doc.name: doc.user
            for (dt, _n), doc in self.frappe._docs.items()
            if dt == "Wallet"
        }
        rows = [
            d
            for d in self.frappe._inserted
            if d.doctype == "Wallet History"
        ]
        if user is None:
            return rows
        return [r for r in rows if wallets.get(r.wallet) == user]

    def commission_rows(self):
        return [
            d
            for d in self.frappe._inserted
            if d.doctype == "Order Commission"
        ]

    def enable_commission_settings(self, item=None, delivery=None):
        f = self.frappe
        f._docs[("DocType", "Commission Settings")] = _Doc(
            name="Commission Settings"
        )
        f._docs[("Commission Settings", "Commission Settings")] = _Doc(
            doctype="Commission Settings",
            name="Commission Settings",
            item_commission_percent=item,
            delivery_commission_percent=delivery,
        )

    def enable_legacy_delivery_default(self, rate):
        f = self.frappe
        f._docs[("DocType", "DeliveryMan Settings")] = _Doc(
            name="DeliveryMan Settings"
        )
        f._docs[("DeliveryMan Settings", "DeliveryMan Settings")] = _Doc(
            doctype="DeliveryMan Settings",
            name="DeliveryMan Settings",
            default_commission_rate=rate,
        )

    def add_driver_profile(self, override=0, percent=None):
        f = self.frappe
        f._meta_fields["Deliveryman Profile"] = {
            "override_delivery_commission",
            "delivery_commission_percent",
        }
        f._docs[("DocType", "Deliveryman Profile")] = _Doc(
            name="Deliveryman Profile"
        )
        f._docs[("Deliveryman Profile", "DMP-1")] = _Doc(
            doctype="Deliveryman Profile",
            name="DMP-1",
            user="driver@example.com",
            override_delivery_commission=override,
            delivery_commission_percent=percent,
        )

    def add_refund(self, name="REF-1", amount=None):
        doc = _Doc(
            doctype="Order Refund",
            name=name,
            order="ORD-1",
            user="buyer@example.com",
            status="Accepted",
            amount=amount,
            clawback_settled=0,
            clawback_amount=0,
        )
        self.frappe._docs[("Order Refund", name)] = doc
        return doc


class TestSettleOrder(SettlementTestBase):
    def test_non_cod_settlement_moves(self):
        result = self.settlement.settle_order(self.order)
        self.assertTrue(result["settled"])
        # Items portion 100 - 10 - 5 = 85; commission 10% of 85 = 8.5.
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 76.5
        )
        # Driver gets the delivery fee; no COD debit (not a cash order).
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 10.0
        )
        self.assertEqual(len(self.history_rows()), 3)
        self.assertEqual(self.order.settled, 1)

    def test_commission_billed_on_items_portion_not_full_total(self):
        # The stored Order.commission_fee convention would be 10% of the
        # 100 total (=10); the billed commission is 10% of the 85 items
        # portion instead.
        self.settlement.settle_order(self.order)
        rows = self.commission_rows()
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].base_amount, 85.0)
        self.assertEqual(rows[0].commission_amount, 8.5)
        self.assertEqual(rows[0].rate, 10.0)
        self.assertEqual(rows[0].status, "Billed")
        self.assertEqual(rows[0].order, "ORD-1")
        self.assertEqual(rows[0].shop, "SHOP-1")

    def test_settlement_is_idempotent(self):
        self.settlement.settle_order(self.order)
        second = self.settlement.settle_order(self.order)
        self.assertFalse(second["settled"])
        self.assertEqual(second["reason"], "already-settled")
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 76.5
        )
        self.assertEqual(len(self.commission_rows()), 1)

    def test_stale_doc_cannot_double_settle(self):
        # A second writer holding a stale in-memory doc (settled=0) must
        # be stopped by the DB re-read under lock.
        self.settlement.settle_order(self.order)
        stale = _Doc(**vars(self.order))
        stale.settled = 0
        result = self.settlement.settle_order(stale)
        self.assertFalse(result["settled"])
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 76.5
        )

    def test_not_delivered_or_not_paid_does_not_settle(self):
        for status, payment in (
            ("Shipped", "Paid"),
            ("Delivered", "Pending"),
            ("Delivered", "Credit"),
        ):
            self.order.status = status
            self.order.payment_status = payment
            result = self.settlement.settle_order(self.order)
            self.assertFalse(result["settled"])
        self.assertIsNone(self.wallet_balance("seller@example.com"))
        self.assertEqual(self.commission_rows(), [])

    def test_cod_debits_driver_gross_collected(self):
        self.order.cod_collected_amount = 100.0
        self.settlement.settle_order(self.order)
        # +10 delivery fee, -100 gross cash kept: negative is allowed.
        self.assertEqual(
            self.wallet_balance("driver@example.com"), -90.0
        )
        cod = [
            r
            for r in self.history_rows("driver@example.com")
            if r.transaction_type == "COD Collection"
        ]
        self.assertEqual(len(cod), 1)
        self.assertEqual(cod[0].amount, -100.0)

    def test_cash_transaction_falls_back_to_total_price(self):
        f = self.frappe
        f._docs[("PaaS Payment Gateway", "Cash")] = _Doc(
            name="Cash", gateway_controller="Cash"
        )
        f._docs[("Transaction", "TXN-1")] = _Doc(
            doctype="Transaction",
            name="TXN-1",
            payable_type="Order",
            payable_id="ORD-1",
            payment_gateway="Cash",
        )
        self.order.cod_collected_amount = 0
        self.settlement.settle_order(self.order)
        self.assertEqual(
            self.wallet_balance("driver@example.com"), -90.0
        )

    def test_missing_deliveryman_skips_driver_moves(self):
        self.order.deliveryman = None
        self.order.cod_collected_amount = 100.0
        result = self.settlement.settle_order(self.order)
        self.assertTrue(result["settled"])
        self.assertIsNone(self.wallet_balance("driver@example.com"))
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 76.5
        )

    def test_zero_fees_and_zero_commission(self):
        self.frappe._docs[("Shop", "SHOP-1")].percentage = 0
        self.order.delivery_fee = 0
        self.order.service_fee = 0
        result = self.settlement.settle_order(self.order)
        self.assertTrue(result["settled"])
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 100.0
        )
        # No driver credit, no commission debit; one history row.
        self.assertIsNone(self.wallet_balance("driver@example.com"))
        self.assertEqual(len(self.history_rows()), 1)
        rows = self.commission_rows()
        self.assertEqual(rows[0].commission_amount, 0)

    def test_wallets_locked_in_sorted_order(self):
        self.settlement.settle_order(self.order)
        wallet_locks = [
            name
            for (dt, name) in self.frappe._locks
            if dt == "Wallet"
        ]
        self.assertEqual(wallet_locks, sorted(wallet_locks))
        self.assertEqual(len(set(wallet_locks)), len(wallet_locks))

    def test_legacy_user_balance_mirror_is_shifted(self):
        f = self.frappe
        f._meta_fields["User"] = {"wallet_balance"}
        f._docs[("User", "seller@example.com")] = _Doc(
            name="seller@example.com", wallet_balance=5.0
        )
        f._docs[("User", "driver@example.com")] = _Doc(
            name="driver@example.com", wallet_balance=0.0
        )
        self.settlement.settle_order(self.order)
        self.assertEqual(
            f._docs[("User", "seller@example.com")].wallet_balance,
            81.5,  # 5 existing + net 76.5
        )
        self.assertEqual(
            f._docs[("User", "driver@example.com")].wallet_balance,
            10.0,
        )

    def test_missing_settled_field_refuses_to_move_money(self):
        self.frappe._meta_fields["Order"] = set()
        result = self.settlement.settle_order(self.order)
        self.assertFalse(result["settled"])
        self.assertIsNone(self.wallet_balance("seller@example.com"))


class TestCommissionRateResolution(SettlementTestBase):
    """Commission v2: platform-wide defaults with per-party overrides.

    Item rate: nonzero Shop.percentage -> Commission Settings
    item_commission_percent -> 0. Delivery rate: Deliveryman Profile
    override (0 and 100 both valid) -> Commission Settings
    delivery_commission_percent -> legacy DeliveryMan Settings
    default_commission_rate -> 0.
    """

    def delivery_commission_rows(self):
        return [
            r
            for r in self.commission_rows()
            if r.get("commission_type") == "Delivery"
        ]

    def test_item_commission_falls_back_to_platform_default(self):
        self.frappe._docs[("Shop", "SHOP-1")].percentage = 0
        self.enable_commission_settings(item=20.0)
        result = self.settlement.settle_order(self.order)
        # 20% of the 85 items portion = 17.
        self.assertEqual(result["commission"], 17.0)
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 68.0
        )
        item_rows = [
            r
            for r in self.commission_rows()
            if r.get("commission_type") == "Item"
        ]
        self.assertEqual(item_rows[0].rate, 20.0)
        self.assertEqual(item_rows[0].party, "seller@example.com")

    def test_shop_percentage_overrides_platform_item_default(self):
        self.enable_commission_settings(item=20.0)  # shop stays at 10%
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["commission"], 8.5)

    def test_no_settings_means_no_delivery_commission(self):
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["delivery_commission"], 0.0)
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 10.0
        )
        self.assertEqual(self.delivery_commission_rows(), [])

    def test_platform_delivery_default_billed_to_driver(self):
        self.enable_commission_settings(delivery=25.0)
        result = self.settlement.settle_order(self.order)
        # 25% of the 10 delivery fee = 2.5; driver nets 10 - 2.5.
        self.assertEqual(result["delivery_commission"], 2.5)
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 7.5
        )
        rows = self.delivery_commission_rows()
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].rate, 25.0)
        self.assertEqual(rows[0].base_amount, 10.0)
        self.assertEqual(rows[0].commission_amount, 2.5)
        self.assertEqual(rows[0].party, "driver@example.com")
        self.assertEqual(rows[0].order, "ORD-1")
        self.assertEqual(rows[0].status, "Billed")

    def test_driver_override_wins_over_platform_default(self):
        self.enable_commission_settings(delivery=25.0)
        self.add_driver_profile(override=1, percent=50.0)
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["delivery_commission"], 5.0)
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 5.0
        )

    def test_driver_override_zero_percent_keeps_whole_fee(self):
        self.enable_commission_settings(delivery=25.0)
        self.add_driver_profile(override=1, percent=0.0)
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["delivery_commission"], 0.0)
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 10.0
        )
        self.assertEqual(self.delivery_commission_rows(), [])

    def test_driver_override_hundred_percent_takes_whole_fee(self):
        # Salaried-driver case: the platform takes the whole fee.
        self.add_driver_profile(override=1, percent=100.0)
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["delivery_commission"], 10.0)
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 0.0
        )

    def test_unchecked_override_falls_back_to_platform_default(self):
        self.enable_commission_settings(delivery=25.0)
        self.add_driver_profile(override=0, percent=50.0)
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["delivery_commission"], 2.5)

    def test_legacy_deliveryman_settings_is_last_fallback(self):
        self.enable_legacy_delivery_default(30.0)
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["delivery_commission"], 3.0)
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 7.0
        )

    def test_platform_default_beats_legacy_single(self):
        self.enable_commission_settings(delivery=25.0)
        self.enable_legacy_delivery_default(30.0)
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["delivery_commission"], 2.5)

    def test_rays_cod_worked_example(self):
        # COD 120 = 100 items + 20 delivery, item rate 10%, delivery
        # rate 25%: driver nets -100 - 25%x20 = -105; shop nets
        # +100 - 10 = +90. Every move on the books.
        self.order.total_price = 120.0
        self.order.delivery_fee = 20.0
        self.order.service_fee = 0.0
        self.order.cod_collected_amount = 120.0
        self.enable_commission_settings(delivery=25.0)
        self.settlement.settle_order(self.order)
        self.assertEqual(
            self.wallet_balance("driver@example.com"), -105.0
        )
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 90.0
        )

    def test_refund_reverses_item_commission_only(self):
        self.enable_commission_settings(delivery=25.0)
        self.settlement.settle_order(self.order)
        refund = self.add_refund()
        result = self.settlement.apply_refund_clawback(refund)
        self.assertTrue(result["refunded"])
        # Item commission (8.5) reversed; the Delivery row untouched —
        # the delivery happened, the driver keeps fee and commission.
        self.assertEqual(result["commission_reversed"], 8.5)
        rows = self.delivery_commission_rows()
        self.assertEqual(rows[0].reversed_amount, 0)
        self.assertEqual(rows[0].status, "Billed")
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 7.5
        )


class TestCreditDeliverySettlement(SettlementTestBase):
    """Delivered-while-Credit orders settle the driver AND platform
    shares immediately, all fronted by the shop (which alone carries
    the credit risk); the later Paid settlement credits the shop the
    FULL total and touches nobody else."""

    def setUp(self):
        super().setUp()
        self.frappe._meta_fields["Order"] = {"settled", "credit_settled"}
        # Ray's worked example shape: 120 total = 100 items + 20
        # delivery, no service fee; item rate 10% (Shop.percentage),
        # delivery rate 25% (platform default).
        self.order.payment_status = "Credit"
        self.order.total_price = 120.0
        self.order.delivery_fee = 20.0
        self.order.service_fee = 0.0
        self.order.credit_settled = 0
        self.enable_commission_settings(delivery=25.0)

    def typed_rows(self, commission_type):
        return [
            r
            for r in self.commission_rows()
            if r.get("commission_type") == commission_type
        ]

    def test_credit_delivery_bills_shop_all_shares(self):
        result = self.settlement.settle_credit_delivery(self.order)
        self.assertTrue(result["credit_settled"])
        self.assertEqual(result["delivery_fee"], 20.0)
        self.assertEqual(result["delivery_commission"], 5.0)
        self.assertEqual(result["item_commission"], 10.0)
        # Shop fronts fee + item commission (+ service 0): -30.
        # Driver nets fee minus delivery commission: +15.
        # Platform's take (10 + 5) leaves the wallet ledger.
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -30.0
        )
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 15.0
        )
        # Item AND Delivery rows billed NOW, at credit delivery.
        item_rows = self.typed_rows("Item")
        self.assertEqual(len(item_rows), 1)
        self.assertEqual(item_rows[0].commission_amount, 10.0)
        self.assertEqual(item_rows[0].status, "Billed")
        delivery_rows = self.typed_rows("Delivery")
        self.assertEqual(len(delivery_rows), 1)
        self.assertEqual(delivery_rows[0].commission_amount, 5.0)
        # No service fee -> no Service row.
        self.assertEqual(self.typed_rows("Service"), [])
        self.assertEqual(self.order.credit_settled, 1)

    def test_credit_delivery_bills_service_fee_with_row(self):
        # Variant with a service fee: 125 total = 100 items + 20
        # delivery + 5 service; item commission still 10% of 100.
        self.order.total_price = 125.0
        self.order.service_fee = 5.0
        result = self.settlement.settle_credit_delivery(self.order)
        self.assertTrue(result["credit_settled"])
        self.assertEqual(result["service_fee"], 5.0)
        self.assertEqual(result["item_commission"], 10.0)
        # Shop: -(20 + 10 + 5) = -35.
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -35.0
        )
        service_rows = self.typed_rows("Service")
        self.assertEqual(len(service_rows), 1)
        self.assertEqual(service_rows[0].commission_amount, 5.0)
        self.assertEqual(service_rows[0].base_amount, 5.0)
        # Repayment: shop +125 -> nets 90 (= items - item commission).
        self.order.payment_status = "Paid"
        result = self.settlement.settle_order(self.order)
        self.assertEqual(result["shop_credit"], 125.0)
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 90.0
        )

    def test_credit_delivery_is_idempotent(self):
        self.settlement.settle_credit_delivery(self.order)
        second = self.settlement.settle_credit_delivery(self.order)
        self.assertFalse(second["credit_settled"])
        self.assertEqual(second["reason"], "already-settled")
        stale = _Doc(**vars(self.order))
        stale.credit_settled = 0
        third = self.settlement.settle_credit_delivery(stale)
        self.assertFalse(third["credit_settled"])
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -30.0
        )
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 15.0
        )
        self.assertEqual(len(self.typed_rows("Item")), 1)
        self.assertEqual(len(self.typed_rows("Delivery")), 1)

    def test_credit_delivery_without_driver_still_bills_platform(self):
        # No driver leg, but the platform shares are still taken up
        # front — the shop carries the credit risk, nobody else.
        self.order.deliveryman = None
        result = self.settlement.settle_credit_delivery(self.order)
        self.assertTrue(result["credit_settled"])
        self.assertEqual(result["delivery_fee"], 0.0)
        self.assertEqual(result["delivery_commission"], 0.0)
        self.assertEqual(result["item_commission"], 10.0)
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -10.0
        )
        self.assertIsNone(self.wallet_balance("driver@example.com"))
        self.assertEqual(self.typed_rows("Delivery"), [])
        self.assertEqual(self.order.credit_settled, 1)

    def test_credit_delivery_only_when_delivered_and_credit(self):
        for status, payment in (
            ("Shipped", "Credit"),
            ("Delivered", "Pending"),
            ("Delivered", "Paid"),
        ):
            self.order.status = status
            self.order.payment_status = payment
            result = self.settlement.settle_credit_delivery(self.order)
            self.assertFalse(result["credit_settled"])
        self.assertIsNone(self.wallet_balance("driver@example.com"))
        self.assertIsNone(self.wallet_balance("seller@example.com"))

    def test_credit_delivery_missing_field_refuses(self):
        self.frappe._meta_fields["Order"] = {"settled"}
        result = self.settlement.settle_credit_delivery(self.order)
        self.assertFalse(result["credit_settled"])
        self.assertEqual(
            result["reason"], "credit-settled-field-missing"
        )
        self.assertIsNone(self.wallet_balance("driver@example.com"))

    def test_credit_delivery_refused_after_full_settlement(self):
        self.order.settled = 1
        result = self.settlement.settle_credit_delivery(self.order)
        self.assertFalse(result["credit_settled"])
        self.assertEqual(result["reason"], "order-fully-settled")

    def test_repayment_credits_shop_full_total_touches_nobody_else(self):
        self.settlement.settle_credit_delivery(self.order)
        self.order.payment_status = "Paid"
        result = self.settlement.settle_order(self.order)
        self.assertTrue(result["settled"])
        self.assertTrue(result["credit_settled_order"])
        # FULL total, nothing deducted: shop recoups all it fronted.
        self.assertEqual(result["shop_credit"], 120.0)
        self.assertEqual(result["commission"], 0.0)
        self.assertEqual(result["delivery_fee_credit"], 0)
        self.assertEqual(result["delivery_commission"], 0.0)
        # Net: shop -30 + 120 = 90 (= items - item commission);
        # driver untouched at 15; platform kept 10 + 5.
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 90.0
        )
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 15.0
        )
        # Item and Delivery rows exist exactly once — billed at credit
        # delivery, never re-billed at repayment.
        self.assertEqual(len(self.typed_rows("Item")), 1)
        self.assertEqual(len(self.typed_rows("Delivery")), 1)

    def test_non_credit_settled_paid_settlement_regression(self):
        # Same figures WITHOUT a credit delivery: shipped math stands —
        # shop gets the items portion minus item commission, driver
        # gets fee minus delivery commission, all at settlement.
        self.order.payment_status = "Paid"
        result = self.settlement.settle_order(self.order)
        self.assertTrue(result["settled"])
        self.assertFalse(result["credit_settled_order"])
        self.assertEqual(result["shop_credit"], 100.0)
        self.assertEqual(result["commission"], 10.0)
        self.assertEqual(result["delivery_fee_credit"], 20.0)
        self.assertEqual(result["delivery_commission"], 5.0)
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 90.0
        )
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 15.0
        )

    def test_rays_worked_example_full_repayment_via_wallet(self):
        # Credit delivery: shop -30, driver +15, platform +10 +5.
        # Repayment sweep: customer -120, shop +120.
        # Net: shop 90 (= items - itemComm), driver 15, platform 15.
        self.settlement.settle_credit_delivery(self.order)
        f = self.frappe
        f._docs[("Wallet", "WAL-buyer")] = _Doc(
            doctype="Wallet",
            name="WAL-buyer",
            user="buyer@example.com",
            balance=120.0,
        )
        pay = self.settlement.auto_pay_credit_orders(
            "buyer@example.com"
        )
        self.assertEqual(pay["orders_paid"], ["ORD-1"])
        self.assertEqual(
            self.wallet_balance("buyer@example.com"), 0.0
        )
        self.assertEqual(self.order.payment_status, "Paid")
        result = self.settlement.settle_order(self.order)
        self.assertTrue(result["settled"])
        self.assertEqual(
            self.wallet_balance("seller@example.com"), 90.0
        )
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 15.0
        )

    def test_partial_collection_then_full_autopay(self):
        self.settlement.settle_credit_delivery(self.order)
        f = self.frappe
        wallet = _Doc(
            doctype="Wallet",
            name="WAL-buyer",
            user="buyer@example.com",
            balance=50.0,
        )
        f._docs[("Wallet", "WAL-buyer")] = wallet
        pay = self.settlement.auto_pay_credit_orders(
            "buyer@example.com"
        )
        self.assertEqual(pay["orders_paid"], [])
        self.assertEqual(self.order.payment_status, "Credit")
        self.assertEqual(
            self.wallet_balance("buyer@example.com"), 50.0
        )
        # Later collections bring the balance to the full total.
        wallet.balance = 120.0
        pay = self.settlement.auto_pay_credit_orders(
            "buyer@example.com"
        )
        self.assertEqual(pay["orders_paid"], ["ORD-1"])
        self.assertEqual(self.order.payment_status, "Paid")
        # Driver and shop-fronted shares untouched by the sweep.
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 15.0
        )
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -30.0
        )

    def test_refund_clawback_on_credit_settled_order(self):
        # Full refund after credit delivery + repayment. The clawback
        # formula is unchanged (buyer credited what he paid, shop
        # debited that minus the proportional Item-commission
        # reversal) and it accounts for the shop having received the
        # FULL total at repayment:
        #   shop position before refund: -30 + 120 = 90
        #   shop debit: 120 - 10 (item commission reversed back) = 110
        #   shop after: 90 - 110 = -20 = -(delivery_fee + service_fee)
        # i.e. exactly the driver's fee the shop fronted for a
        # fully-refunded order — the same "shop carries the delivery
        # portion" outcome as the non-credit path. Driver keeps fee and
        # delivery commission (delivery happened); the Delivery row
        # stays unreversed, the Item row is reversed.
        self.settlement.settle_credit_delivery(self.order)
        self.order.payment_status = "Paid"
        self.settlement.settle_order(self.order)
        refund = self.add_refund()
        result = self.settlement.apply_refund_clawback(refund)
        self.assertTrue(result["refunded"])
        self.assertEqual(result["buyer_credit"], 120.0)
        self.assertEqual(result["commission_reversed"], 10.0)
        self.assertEqual(result["shop_debit"], 110.0)
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -20.0
        )
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 15.0
        )
        self.assertEqual(
            self.wallet_balance("buyer@example.com"), 120.0
        )
        item_rows = self.typed_rows("Item")
        self.assertEqual(item_rows[0].reversed_amount, 10.0)
        self.assertEqual(item_rows[0].status, "Reversed")
        delivery_rows = self.typed_rows("Delivery")
        self.assertEqual(delivery_rows[0].reversed_amount, 0)
        self.assertEqual(delivery_rows[0].status, "Billed")

    def test_unpaid_credit_settled_order_refunds_nothing(self):
        # The credit was never repaid: the shop alone is out (design);
        # a refund approval moves nothing.
        self.settlement.settle_credit_delivery(self.order)
        refund = self.add_refund()
        result = self.settlement.apply_refund_clawback(refund)
        self.assertFalse(result["refunded"])
        self.assertEqual(result["buyer_credit"], 0.0)
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -30.0
        )


class TestRefundClawback(SettlementTestBase):
    def test_full_refund_after_settlement(self):
        self.settlement.settle_order(self.order)
        refund = self.add_refund()
        result = self.settlement.apply_refund_clawback(refund)
        self.assertTrue(result["refunded"])
        self.assertEqual(result["buyer_credit"], 100.0)
        # Shop pays back the refund minus the commission reversal:
        # 100 - 8.5 = 91.5 → 76.5 - 91.5 = -15 (negative allowed).
        self.assertEqual(result["shop_debit"], 91.5)
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -15.0
        )
        self.assertEqual(
            self.wallet_balance("buyer@example.com"), 100.0
        )
        # Driver keeps his delivery-fee credit untouched.
        self.assertEqual(
            self.wallet_balance("driver@example.com"), 10.0
        )
        row = self.commission_rows()[0]
        self.assertEqual(row.status, "Reversed")
        self.assertEqual(row.reversed_amount, 8.5)
        self.assertEqual(refund.clawback_settled, 1)
        self.assertEqual(refund.clawback_amount, 100.0)

    def test_partial_refund_reverses_commission_proportionally(self):
        self.settlement.settle_order(self.order)
        refund = self.add_refund(amount=50.0)
        result = self.settlement.apply_refund_clawback(refund)
        self.assertEqual(result["buyer_credit"], 50.0)
        self.assertEqual(result["commission_reversed"], 4.25)
        self.assertEqual(result["shop_debit"], 45.75)
        row = self.commission_rows()[0]
        self.assertEqual(row.status, "Billed")  # only partly reversed
        self.assertEqual(row.reversed_amount, 4.25)

    def test_reapproval_cannot_double_move(self):
        self.settlement.settle_order(self.order)
        refund = self.add_refund()
        self.settlement.apply_refund_clawback(refund)
        second = self.settlement.apply_refund_clawback(refund)
        self.assertFalse(second["refunded"])
        self.assertEqual(second["reason"], "already-refunded")
        self.assertEqual(
            self.wallet_balance("buyer@example.com"), 100.0
        )

    def test_cumulative_refunds_capped_at_collected(self):
        self.settlement.settle_order(self.order)
        self.settlement.apply_refund_clawback(self.add_refund("REF-1"))
        result = self.settlement.apply_refund_clawback(
            self.add_refund("REF-2")
        )
        self.assertFalse(result["refunded"])
        self.assertEqual(result["buyer_credit"], 0.0)
        self.assertEqual(
            self.wallet_balance("buyer@example.com"), 100.0
        )
        # Second refund is still flag-closed so it cannot re-fire.
        self.assertEqual(
            self.frappe._docs[
                ("Order Refund", "REF-2")
            ].clawback_settled,
            1,
        )

    def test_two_partials_reverse_commission_fully(self):
        self.settlement.settle_order(self.order)
        self.settlement.apply_refund_clawback(
            self.add_refund("REF-1", amount=50.0)
        )
        self.settlement.apply_refund_clawback(
            self.add_refund("REF-2", amount=50.0)
        )
        row = self.commission_rows()[0]
        self.assertEqual(row.reversed_amount, 8.5)
        self.assertEqual(row.status, "Reversed")
        self.assertEqual(
            self.wallet_balance("seller@example.com"), -15.0
        )

    def test_unsettled_paid_order_credits_buyer_only(self):
        # Wallet/gateway-paid but not yet Delivered: platform holds the
        # money, the shop never received it.
        self.order.status = "Accepted"
        refund = self.add_refund()
        result = self.settlement.apply_refund_clawback(refund)
        self.assertTrue(result["refunded"])
        self.assertEqual(
            self.wallet_balance("buyer@example.com"), 100.0
        )
        self.assertEqual(result["shop_debit"], 0.0)
        self.assertIsNone(self.wallet_balance("seller@example.com"))

    def test_uncollected_order_refunds_nothing(self):
        # Unpaid / uncollected COD / Credit hand-over: the platform
        # collected nothing, so nobody is credited or debited.
        for payment in ("Pending", "Credit", "Failed"):
            self.order.payment_status = payment
            refund = self.add_refund("REF-" + payment)
            result = self.settlement.apply_refund_clawback(refund)
            self.assertFalse(result["refunded"])
            self.assertEqual(result["buyer_credit"], 0.0)
        self.assertIsNone(self.wallet_balance("buyer@example.com"))
        self.assertIsNone(self.wallet_balance("seller@example.com"))

    def test_missing_clawback_field_refuses_to_move_money(self):
        self.settlement.settle_order(self.order)
        self.frappe._meta_fields["Order Refund"] = set()
        refund = self.add_refund()
        result = self.settlement.apply_refund_clawback(refund)
        self.assertFalse(result["refunded"])
        self.assertIsNone(self.wallet_balance("buyer@example.com"))


if __name__ == "__main__":
    unittest.main()
