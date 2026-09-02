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

"""convert_delivery_to_collected — the customer turned up for a delivery
order (design strip section 43), unit-tested without a bench.

This suite is deliberately an INTEGRATION one over a stub ``frappe``:
the endpoint, the real Order controller (``before_save`` /``on_update``
with its settlement triggers) and the real settlement module are all
loaded from source and wired together the way the composed app wires
them. Nothing about the money is faked, because the money is the point.

The load-bearing case is ``test_driver_is_paid_his_callout_exactly_once``
and its twin ``test_reversed_ordering_pays_the_driver_twice``:

  ``settle_order`` credits the deliveryman the FULL ``delivery_fee`` the
  moment an order reaches Delivered + Paid while ``deliveryman`` is still
  set. The conversion also owes him that fee — he drove for it — so it
  pays it as a callout. If the conversion writes Delivered BEFORE it
  clears the assignment, both credits land and the driver is paid twice.
  The assertion is on his WALLET BALANCE and his wallet-history rows, not
  on the order of any calls: reverse the two writes in
  ``convert_delivery_to_collected`` and the first test fails on the
  number, exactly as the second test demonstrates.

Run standalone:
    python3 -m unittest merchants/frappe/tests/test_collect_in_person.py
"""

import importlib.util
import sys
import types
import unittest
from datetime import datetime
from pathlib import Path

HAVE_REAL_FRAPPE = importlib.util.find_spec("frappe") is not None

_MERCHANTS = Path(__file__).resolve().parents[1]
_COMMERCE = _MERCHANTS.parents[1]
_ORDERS_TENANT = _COMMERCE / "orders" / "frappe" / "src" / "tenant"

_SELLER_ORDER_PY = (
    _MERCHANTS / "src" / "tenant" / "api" / "seller_order" / "seller_order.py"
)
_SETTLEMENT_PY = _ORDERS_TENANT / "api" / "order" / "settlement.py"
_ORDER_API_PY = _ORDERS_TENANT / "api" / "order" / "order.py"
_ORDER_DOCTYPE_PY = _ORDERS_TENANT / "doctype" / "order" / "order.py"


class _AttrDict(dict):
    def __getattr__(self, key):
        try:
            return self[key]
        except KeyError:
            return None


class _Doc(types.SimpleNamespace):
    def get(self, key, default=None):
        return getattr(self, key, default)

    def save(self, ignore_permissions=False):
        return self

    def as_dict(self):
        return dict(self.__dict__)


class _Item(types.SimpleNamespace):
    pass


def _install_stub_frappe():
    """A minimal in-memory frappe: docs, wallets, meta and a session."""
    frappe = types.ModuleType("frappe")

    class ValidationError(Exception):
        pass

    class PermissionError_(Exception):
        pass

    class DoesNotExistError(Exception):
        pass

    frappe.ValidationError = ValidationError
    frappe.PermissionError = PermissionError_
    frappe.DoesNotExistError = DoesNotExistError
    frappe.session = types.SimpleNamespace(user="seller@example.com")
    frappe.request = None
    frappe.utils = types.SimpleNamespace(
        now_datetime=lambda: datetime(2026, 8, 30, 14, 31, 0)
    )

    frappe._docs = {}
    frappe._inserted = []
    frappe._committed = 0
    frappe._meta_fields = {}

    def whitelist(*args, **kwargs):
        if args and callable(args[0]):
            return args[0]

        def deco(fn):
            return fn

        return deco

    frappe.whitelist = whitelist

    def throw(msg, exc=ValidationError):
        raise exc(msg)

    frappe.throw = throw

    def _match(doc, filters):
        for key, wanted in (filters or {}).items():
            if getattr(doc, key, None) != wanted:
                return False
        return True

    def _find(doctype, filters):
        for (dt, _n), doc in sorted(frappe._docs.items()):
            if dt == doctype and _match(doc, filters):
                return doc
        return None

    def get_value(doctype, filters, fieldname="name", as_dict=False,
                  for_update=False, **kwargs):
        doc = (_find(doctype, filters) if isinstance(filters, dict)
               else frappe._docs.get((doctype, filters)))
        if doc is None:
            return None
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
            raise DoesNotExistError("{0} {1}".format(doctype, name))
        updates = field if isinstance(field, dict) else {field: value}
        for key, val in updates.items():
            setattr(doc, key, val)

    def exists(doctype, name=None):
        if isinstance(name, dict):
            return _find(doctype, name)
        return name if (doctype, name) in frappe._docs else None

    def get_single_value(doctype, fieldname):
        doc = frappe._docs.get((doctype, doctype))
        return None if doc is None else getattr(doc, fieldname, None)

    def count(doctype, filters=None):
        return 0

    def commit():
        frappe._committed += 1

    frappe.db = types.SimpleNamespace(
        get_value=get_value,
        set_value=set_value,
        exists=exists,
        get_single_value=get_single_value,
        count=count,
        commit=commit,
    )

    def get_all(doctype, filters=None, fields=None, **kwargs):
        rows = []
        for (dt, _n), doc in sorted(frappe._docs.items()):
            if dt == doctype and _match(doc, filters):
                rows.append(
                    _AttrDict(
                        {f: getattr(doc, f, None)
                         for f in (fields or ["name"])}
                    )
                )
        return rows

    frappe.get_all = get_all
    frappe.get_list = get_all

    def get_doc(*args, **kwargs):
        if len(args) == 1 and isinstance(args[0], dict):
            doc = _Doc(**dict(args[0]))

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
        doc = frappe._docs.get((doctype, name))
        if doc is None:
            raise DoesNotExistError("{0} {1}".format(doctype, name))
        return doc

    frappe.get_doc = get_doc
    frappe.get_roles = lambda user: []

    def get_meta(doctype):
        known = frappe._meta_fields.get(doctype, set())
        return types.SimpleNamespace(has_field=lambda f: f in known)

    frappe.get_meta = get_meta

    model = types.ModuleType("frappe.model")
    document = types.ModuleType("frappe.model.document")

    class Document:
        """Enough of Document for the Order controller: a save runs
        before_save, writes the row, then fires on_update — which is
        exactly where the settlement triggers live."""

        def __init__(self, **fields):
            self.__dict__.update(fields)
            self._before = None
            self._new = True

        def get(self, key, default=None):
            return getattr(self, key, default)

        def set(self, key, value):
            setattr(self, key, value)

        def as_dict(self):
            return {
                k: v for k, v in self.__dict__.items()
                if not k.startswith("_")
            }

        def is_new(self):
            return self._new

        def get_doc_before_save(self):
            return self._before

        def reload(self):
            return self

        def save(self, ignore_permissions=False):
            key = (self.doctype, self.name)
            snapshot = frappe._snapshots.get(key)
            self._new = snapshot is None
            self._before = (
                None if snapshot is None else _Doc(**snapshot)
            )
            self.before_save()
            frappe._docs[key] = self
            frappe._snapshots[key] = dict(self.as_dict())
            self.on_update()
            return self

        def before_save(self):
            pass

        def on_update(self):
            pass

    document.Document = Document
    model.document = document
    frappe.model = model
    frappe._snapshots = {}

    sys.modules["frappe"] = frappe
    sys.modules["frappe.model"] = model
    sys.modules["frappe.model.document"] = document
    return frappe


def _package(name):
    mod = types.ModuleType(name)
    mod.__path__ = []
    sys.modules[name] = mod
    return mod


def _exec_module(name, path, package, substitute=False):
    source = path.read_text(encoding="utf-8")
    if substitute:
        source = source.replace("{app_name}", "paas")
    mod = types.ModuleType(name)
    mod.__file__ = str(path)
    mod.__package__ = package
    sys.modules[name] = mod
    exec(compile(source, str(path), "exec"), mod.__dict__)
    return mod


def _load_modules():
    """Register the composed package tree, then load the three real
    modules into it so their imports of each other resolve exactly as
    they do in a composed app."""
    for name in (
        "paas",
        "paas.base",
        "paas.base.tenant",
        "paas.base.tenant.api",
        "paas.orders",
        "paas.orders.tenant",
        "paas.orders.tenant.api",
        "paas.orders.tenant.api.order",
        "paas.orders.doctype",
        "paas.orders.doctype.order",
        "paas.merchants",
        "paas.merchants.tenant",
        "paas.merchants.tenant.api",
        "paas.merchants.tenant.api.seller_order",
    ):
        _package(name)

    utils = types.ModuleType("paas.base.tenant.api.utils")
    utils._get_seller_shop = lambda user: "SHOP-1"
    utils.api_response = lambda data=None, message=None: {
        "data": data, "message": message
    }
    sys.modules["paas.base.tenant.api.utils"] = utils

    idem = types.ModuleType("paas.base.tenant.api.idempotency")
    idem.idempotent = lambda fn: fn
    sys.modules["paas.base.tenant.api.idempotency"] = idem

    settlement = _exec_module(
        "paas.orders.tenant.api.order.settlement",
        _SETTLEMENT_PY,
        "paas.orders.tenant.api.order",
    )
    order_api = _exec_module(
        "paas.orders.tenant.api.order.order",
        _ORDER_API_PY,
        "paas.orders.tenant.api.order",
        substitute=True,
    )
    controller = _exec_module(
        "paas.orders.doctype.order.order",
        _ORDER_DOCTYPE_PY,
        "paas.orders.doctype.order",
    )
    seller_order = _exec_module(
        "paas.merchants.tenant.api.seller_order.seller_order",
        _SELLER_ORDER_PY,
        "paas.merchants.tenant.api.seller_order",
        substitute=True,
    )
    return settlement, order_api, controller, seller_order


@unittest.skipIf(
    HAVE_REAL_FRAPPE,
    "real frappe importable — run FrappeTestCase suites under bench",
)
class CollectInPersonBase(unittest.TestCase):
    ITEM_TOTAL = 213.0
    FEE = 35.0

    @classmethod
    def setUpClass(cls):
        cls.frappe = _install_stub_frappe()
        (
            cls.settlement,
            cls.order_api,
            cls.controller,
            cls.seller_order,
        ) = _load_modules()

    def setUp(self):
        f = self.frappe
        f._docs.clear()
        f._snapshots.clear()
        f._inserted.clear()
        f._meta_fields.clear()
        f._committed = 0
        f._meta_fields["Order"] = {
            "settled",
            "credit_settled",
            "callout_settled",
            "collected_in_person",
            "collect_fee_refunded",
            "pos_paid_amount",
        }
        f._meta_fields["User"] = set()
        f.session.user = "seller@example.com"

        f._docs[("Shop", "SHOP-1")] = _Doc(
            name="SHOP-1",
            user="shopowner@example.com",
            percentage=0.0,
            tax=0,
            auto_complete_at_ready=0,
        )
        f._docs[("User", "driver@example.com")] = _Doc(
            name="driver@example.com", full_name="Thabo Dlamini"
        )

    # -- fixtures ---------------------------------------------------------

    def make_order(self, deliveryman=None, delivery_type="delivery",
                   status="Ready", payment_status="Paid", fee=None):
        fee = self.FEE if fee is None else fee
        order = self.controller.Order(
            doctype="Order",
            name="ORD-2417",
            user="naledi@example.com",
            shop="SHOP-1",
            status=status,
            payment_status=payment_status,
            delivery_type=delivery_type,
            delivery_fee=fee,
            service_fee=0.0,
            total_price=self.ITEM_TOTAL + fee,
            deliveryman=deliveryman,
            cod_collected_amount=0,
            settled=0,
            credit_settled=0,
            callout_settled=0,
            collected_in_person=0,
            collect_fee_refunded=0,
            coupon_code=None,
            order_items=[
                _Item(price=self.ITEM_TOTAL, quantity=1, discount=0,
                      product=None)
            ],
        )
        self.frappe._docs[("Order", order.name)] = order
        self.frappe._snapshots[("Order", order.name)] = dict(order.as_dict())
        return order

    # -- helpers ----------------------------------------------------------

    def wallet_balance(self, user):
        for (dt, _n), doc in self.frappe._docs.items():
            if dt == "Wallet" and doc.user == user:
                return round(float(doc.balance or 0), 6)
        return None

    def history_rows(self, user=None):
        wallets = {
            doc.name: doc.user
            for (dt, _n), doc in self.frappe._docs.items()
            if dt == "Wallet"
        }
        rows = [
            d for d in self.frappe._inserted if d.doctype == "Wallet History"
        ]
        if user is None:
            return rows
        return [r for r in rows if wallets.get(r.wallet) == user]

    def transactions(self, user=None):
        rows = [
            d for d in self.frappe._inserted if d.doctype == "Transaction"
        ]
        if user is None:
            return rows
        return [r for r in rows if r.user == user]

    def convert(self, order_id="ORD-2417"):
        return self.seller_order.convert_delivery_to_collected(order_id)


class DriverAssignedBranch(CollectInPersonBase):
    """A driver had already been dispatched: hand over anyway, keep the
    fee, pay it to him as a callout, stand his task down."""

    def test_driver_is_paid_his_callout_exactly_once(self):
        """THE settlement test.

        The driver is owed the fee once. The conversion pays it, then
        clears the assignment, and only THEN writes Delivered — so the
        controller's settlement, which credits the full delivery_fee to
        an assigned driver, finds nobody to pay. Move the Delivered write
        ahead of the unassign and his balance is 70.00 here, not 35.00.
        """
        self.make_order(deliveryman="driver@example.com")

        self.convert()

        self.assertEqual(self.wallet_balance("driver@example.com"), self.FEE)
        credits = [
            r for r in self.history_rows("driver@example.com")
            if float(r.amount or 0) > 0
        ]
        self.assertEqual(
            len(credits), 1,
            "the driver must be credited the delivery fee exactly once; "
            "got {0} credits: {1}".format(
                len(credits), [r.description for r in credits]
            ),
        )
        self.assertEqual(float(credits[0].amount), self.FEE)

    def test_reversed_ordering_pays_the_driver_twice(self):
        """Why the ordering above is not a matter of taste.

        This is the SAME two writes in the wrong order — Delivered first,
        while the driver is still assigned, then the callout — performed
        directly on the doc. It double-pays, which is exactly what the
        endpoint's ordering exists to prevent and what the test above
        would catch.
        """
        order = self.make_order(deliveryman="driver@example.com")

        # Wrong order: the hand-over is written while he is still on it.
        order.status = "Delivered"
        order.save(ignore_permissions=True)
        # ... and only then is he stood down and paid his callout.
        self.settlement.settle_delivery_callout(order)

        self.assertEqual(
            self.wallet_balance("driver@example.com"), self.FEE * 2,
            "reversing the two writes is expected to double-pay the "
            "driver — if this stops being true the guard above is no "
            "longer testing anything",
        )

    def test_order_becomes_a_delivered_pickup_with_no_driver(self):
        self.make_order(deliveryman="driver@example.com")
        result = self.convert()
        order = self.frappe._docs[("Order", "ORD-2417")]

        self.assertEqual(order.delivery_type, "pickup")
        self.assertIsNone(order.deliveryman)
        self.assertEqual(order.status, "Delivered")
        self.assertEqual(order.collected_in_person, 1)
        self.assertEqual(float(order.collect_fee_refunded or 0), 0.0)
        self.assertEqual(result["fee_outcome"], "kept")
        self.assertTrue(result["driver_was_assigned"])
        self.assertEqual(result["unassigned_deliveryman"],
                         "driver@example.com")

    def test_fee_and_total_are_untouched_when_the_fee_is_kept(self):
        self.make_order(deliveryman="driver@example.com")
        result = self.convert()
        order = self.frappe._docs[("Order", "ORD-2417")]

        self.assertEqual(float(order.delivery_fee), self.FEE)
        self.assertEqual(float(order.total_price), self.ITEM_TOTAL + self.FEE)
        self.assertEqual(result["total_price"], self.ITEM_TOTAL + self.FEE)
        self.assertEqual(result["total_price_before"],
                         self.ITEM_TOTAL + self.FEE)
        self.assertEqual(result["refunded_to_wallet"], 0.0)

    def test_customer_is_not_refunded_when_a_driver_was_on_it(self):
        self.make_order(deliveryman="driver@example.com")
        self.convert()
        self.assertIsNone(self.wallet_balance("naledi@example.com"))

    def test_shop_settles_on_the_items_portion_only(self):
        self.make_order(deliveryman="driver@example.com")
        self.convert()
        # total 248 - fee 35 - service 0: the driver's callout came out of
        # the fee, so the shop's share is unchanged by the conversion.
        self.assertEqual(
            self.wallet_balance("shopowner@example.com"), self.ITEM_TOTAL
        )

    def test_delivery_commission_is_billed_on_the_callout(self):
        self.frappe._docs[("DocType", "Commission Settings")] = _Doc(
            name="Commission Settings"
        )
        self.frappe._docs[("Commission Settings", "Commission Settings")] = (
            _Doc(
                doctype="Commission Settings",
                name="Commission Settings",
                item_commission_percent=None,
                delivery_commission_percent=10.0,
            )
        )
        self.make_order(deliveryman="driver@example.com")
        self.convert()

        self.assertEqual(
            self.wallet_balance("driver@example.com"), self.FEE * 0.9
        )
        rows = [
            d for d in self.frappe._inserted
            if d.doctype == "Order Commission"
            and d.commission_type == "Delivery"
        ]
        self.assertEqual(len(rows), 1)
        self.assertEqual(float(rows[0].base_amount), self.FEE)


class NoDriverBranch(CollectInPersonBase):
    """Nobody had been dispatched: the fee goes back to her wallet and
    the order's total drops by it."""

    def test_fee_is_credited_to_the_customer_wallet(self):
        self.make_order(deliveryman=None)
        result = self.convert()

        self.assertEqual(self.wallet_balance("naledi@example.com"), self.FEE)
        rows = self.transactions("naledi@example.com")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0].type, "Refund")
        self.assertEqual(rows[0].status, "Paid")
        self.assertEqual(result["fee_outcome"], "refunded")
        self.assertEqual(result["refunded_to_wallet"], self.FEE)
        self.assertFalse(result["driver_was_assigned"])

    def test_the_refund_does_not_commit_mid_conversion(self):
        """The wallet credit is part of the conversion, not a
        transaction of its own — a failure after it has to be able to
        take it with it."""
        self.make_order(deliveryman=None)
        self.convert()
        self.assertEqual(self.frappe._committed, 0)

    def test_fee_is_zeroed_and_the_total_drops_by_it(self):
        self.make_order(deliveryman=None)
        result = self.convert()
        order = self.frappe._docs[("Order", "ORD-2417")]

        self.assertEqual(float(order.delivery_fee or 0), 0.0)
        self.assertEqual(float(order.total_price), self.ITEM_TOTAL)
        self.assertEqual(float(order.collect_fee_refunded), self.FEE)
        self.assertEqual(result["total_price"], self.ITEM_TOTAL)
        self.assertEqual(result["total_price_before"],
                         self.ITEM_TOTAL + self.FEE)

    def test_nobody_is_credited_a_delivery_fee_at_settlement(self):
        self.make_order(deliveryman=None)
        self.convert()
        fee_credits = [
            r for r in self.history_rows()
            if "Delivery" in str(r.description or "")
        ]
        self.assertEqual(fee_credits, [])

    def test_shop_settles_on_the_items_portion(self):
        self.make_order(deliveryman=None)
        self.convert()
        self.assertEqual(
            self.wallet_balance("shopowner@example.com"), self.ITEM_TOTAL
        )


class ConversionGuards(CollectInPersonBase):
    def test_another_shops_order_is_refused(self):
        self.make_order()
        self.frappe._docs[("Order", "ORD-2417")].shop = "SHOP-2"
        with self.assertRaises(self.frappe.PermissionError):
            self.convert()

    def test_a_pickup_order_has_nothing_to_convert(self):
        self.make_order(delivery_type="pickup")
        with self.assertRaises(self.frappe.ValidationError):
            self.convert()

    def test_a_cancelled_order_is_refused(self):
        self.make_order(status="Cancelled")
        with self.assertRaises(self.frappe.ValidationError):
            self.convert()

    def test_an_already_delivered_order_is_refused(self):
        self.make_order(status="Delivered")
        with self.assertRaises(self.frappe.ValidationError):
            self.convert()

    def test_capitalized_delivery_type_is_accepted_and_mirrored(self):
        self.make_order(delivery_type="Delivery")
        self.convert()
        order = self.frappe._docs[("Order", "ORD-2417")]
        self.assertEqual(order.delivery_type, "Pickup")

    def test_a_second_call_moves_no_money(self):
        self.make_order(deliveryman="driver@example.com")
        self.convert()
        before = self.wallet_balance("driver@example.com")
        rows = len(self.history_rows())

        result = self.convert()

        self.assertTrue(result["already_converted"])
        self.assertEqual(self.wallet_balance("driver@example.com"), before)
        self.assertEqual(len(self.history_rows()), rows)
        self.assertEqual(result["fee_outcome"], "kept")
        self.assertTrue(result["driver_was_assigned"])

    def test_a_second_call_after_a_refund_still_reports_the_refund(self):
        self.make_order(deliveryman=None)
        self.convert()
        result = self.convert()
        self.assertTrue(result["already_converted"])
        self.assertEqual(result["fee_outcome"], "refunded")
        self.assertEqual(result["refunded_to_wallet"], self.FEE)
        self.assertFalse(result["driver_was_assigned"])

    def test_a_zero_fee_delivery_order_converts_with_no_money_moved(self):
        self.make_order(deliveryman=None, fee=0.0)
        result = self.convert()
        self.assertEqual(result["fee_outcome"], "none")
        self.assertIsNone(self.wallet_balance("naledi@example.com"))

    def test_an_unpaid_order_converts_without_settling(self):
        self.make_order(deliveryman="driver@example.com",
                        payment_status="Pending")
        self.convert()
        order = self.frappe._docs[("Order", "ORD-2417")]
        # The driver is still owed his callout the moment he is stood
        # down; the shop's settlement waits for payment as it always did.
        self.assertEqual(self.wallet_balance("driver@example.com"), self.FEE)
        self.assertIsNone(self.wallet_balance("shopowner@example.com"))
        self.assertEqual(int(order.settled or 0), 0)


class SellerOrderDetailName(CollectInPersonBase):
    def test_details_carry_the_drivers_readable_name(self):
        self.make_order(deliveryman="driver@example.com")
        row = self.seller_order.get_seller_order_details("ORD-2417")
        self.assertEqual(row["deliveryman_name"], "Thabo Dlamini")

    def test_details_omit_the_name_when_nobody_is_assigned(self):
        self.make_order(deliveryman=None)
        row = self.seller_order.get_seller_order_details("ORD-2417")
        self.assertNotIn("deliveryman_name", row)


if __name__ == "__main__":
    unittest.main()
