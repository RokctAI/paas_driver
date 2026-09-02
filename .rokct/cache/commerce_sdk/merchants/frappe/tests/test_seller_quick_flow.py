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

"""
Bench-independent tests for seller_shop's Quick flow endpoints
(design strip section 42).

`get_quick_flow_settings` / `update_quick_flow_settings` are the one
surface behind the Quick flow page: the LIVE auto-accept field
(`Shop.auto_approve_orders`, exposed and nothing more), the new
auto-complete-at-Ready switch, and the new keypad-autodial switch with
its digit->product map.

Two things are load-bearing and get their own cases:

* the preset payload carries the product ALREADY SERIALIZED in the
  client's `ProductData` shape (`id` / `translation.title` / `stocks[]`),
  because the till must be able to drop a preset on the ticket without a
  second round trip -- a digit press can never wait on the network;
* the writer OWNS the whole 1-9 map (it rebuilds the child table), and
  refuses a bad digit, a digit mapped twice, a missing product and a
  product belonging to another shop.

The module is exec'd with `{app_name}` substituted, exactly as the
composer installs it -- so this file is also the compile gate for the
composed form of the endpoints.

Runs directly with
`python3 merchants/frappe/tests/test_seller_quick_flow.py`.
"""

import sys
import types
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from test_seller_get_shop import _stub_missing_modules  # noqa: E402

_stub_missing_modules()

_SELLER_SHOP_PY = (
    Path(__file__).resolve().parents[1]
    / "src"
    / "tenant"
    / "api"
    / "seller_shop"
    / "seller_shop.py"
)
_module = types.ModuleType("_seller_shop_quick_flow_under_test")
_module.__file__ = str(_SELLER_SHOP_PY)
exec(
    compile(
        _SELLER_SHOP_PY.read_text().replace("{app_name}", "paas"),
        str(_SELLER_SHOP_PY),
        "exec",
    ),
    _module.__dict__,
)


class _Row(dict):
    def get(self, key, default=None):
        return dict.get(self, key, default)


class _FakeShop:
    def __init__(self, **fields):
        self.name = fields.pop("name", "SHOP-1")
        self._fields = fields
        self.saved = 0

    def get(self, key, default=None):
        return self._fields.get(key, default)

    def set(self, key, value):
        self._fields[key] = value

    def append(self, key, row):
        self._fields.setdefault(key, []).append(_Row(row))

    def save(self, ignore_permissions=False):
        self.saved += 1


class _FakeFrappe:
    """Just enough frappe for the two Quick flow endpoints."""

    class ValidationError(Exception):
        pass

    def __init__(self, shop, products=None, stocks=None, platform=True):
        self.session = types.SimpleNamespace(user="seller@example.com")
        self.shop = shop
        self.products = products or {}
        self.stocks = stocks or {}
        self.platform = platform
        self.db = types.SimpleNamespace(
            get_single_value=self._get_single_value,
            exists=self._exists,
            get_value=self._get_value,
        )

    def whitelist(self, *args, **kwargs):
        return lambda fn: fn

    def throw(self, message, exc=None):
        raise self.ValidationError(message)

    def get_doc(self, doctype, name=None):
        if doctype == "Shop":
            return self.shop
        return self.products[name]

    def get_all(self, doctype, filters=None, fields=None, **kwargs):
        if doctype != "Stock":
            return []
        return self.stocks.get((filters or {}).get("product"), [])

    def _get_single_value(self, doctype, fieldname):
        if doctype == "Permission Settings":
            return 1 if self.platform else 0
        return None

    def _exists(self, doctype, name):
        return doctype == "Product" and name in self.products

    def _get_value(self, doctype, name, fieldname):
        if doctype == "Product" and name in self.products:
            return self.products[name].get(fieldname)
        return None


def _product(name, title, price, shop="SHOP-1"):
    doc = _FakeShop(name=name, title=title, price=price, shop=shop)
    return doc


class QuickFlowReadTest(unittest.TestCase):
    def setUp(self):
        self.shop = _FakeShop(
            name="SHOP-1",
            shop_name="Blue Tap Water Refill",
            auto_approve_orders=1,
            auto_complete_at_ready=0,
            keypad_autodial=1,
            digit_presets=[_Row({"digit": "3", "product": "PROD-20L"})],
        )
        self.frappe = _FakeFrappe(
            self.shop,
            products={"PROD-20L": _product("PROD-20L", "20 L refill", 35.0)},
            stocks={
                "PROD-20L": [
                    {"name": "STK-1", "price": 35.0, "quantity": 12}
                ]
            },
        )
        _module.frappe = self.frappe
        _module._get_seller_shop = lambda user: "SHOP-1"

    def test_reads_the_three_switches_and_the_platform_gate(self):
        payload = _module.get_quick_flow_settings()
        self.assertTrue(payload["auto_accept_orders"])
        self.assertTrue(payload["platform_auto_approve"])
        self.assertFalse(payload["auto_complete_at_ready"])
        self.assertTrue(payload["keypad_autodial"])
        self.assertEqual(payload["shop_name"], "Blue Tap Water Refill")

    def test_preset_carries_a_ready_to_use_product_payload(self):
        preset = _module.get_quick_flow_settings()["digit_presets"][0]
        self.assertEqual(preset["digit"], "3")
        self.assertEqual(preset["product"]["id"], "PROD-20L")
        self.assertEqual(
            preset["product"]["translation"]["title"], "20 L refill"
        )
        self.assertEqual(preset["product"]["stocks"][0]["price"], 35.0)
        self.assertEqual(preset["product"]["stocks"][0]["id"], "STK-1")

    def test_a_product_with_no_stock_row_still_prices_the_key(self):
        self.frappe.stocks = {}
        preset = _module.get_quick_flow_settings()["digit_presets"][0]
        self.assertEqual(preset["product"]["stocks"][0]["price"], 35.0)

    def test_a_preset_whose_product_vanished_is_simply_not_served(self):
        self.frappe.products = {}
        self.assertEqual(
            _module.get_quick_flow_settings()["digit_presets"], []
        )

    def test_the_platform_gate_reads_false_without_the_single(self):
        def boom(*args, **kwargs):
            raise RuntimeError("no Permission Settings on this tenant")

        self.frappe.db.get_single_value = boom
        self.assertFalse(
            _module.get_quick_flow_settings()["platform_auto_approve"]
        )


class QuickFlowWriteTest(unittest.TestCase):
    def setUp(self):
        self.shop = _FakeShop(
            name="SHOP-1",
            shop_name="Blue Tap Water Refill",
            auto_approve_orders=0,
            auto_complete_at_ready=0,
            keypad_autodial=0,
            digit_presets=[],
        )
        self.frappe = _FakeFrappe(
            self.shop,
            products={
                "PROD-5L": _product("PROD-5L", "5 L refill", 12.0),
                "PROD-20L": _product("PROD-20L", "20 L refill", 35.0),
                "PROD-OTHER": _product(
                    "PROD-OTHER", "Someone else's", 9.0, shop="SHOP-2"
                ),
            },
        )
        _module.frappe = self.frappe
        _module._get_seller_shop = lambda user: "SHOP-1"

    def test_writes_only_the_keys_it_was_given(self):
        _module.update_quick_flow_settings({"auto_complete_at_ready": True})
        self.assertEqual(self.shop.get("auto_complete_at_ready"), 1)
        self.assertEqual(self.shop.get("auto_approve_orders"), 0)
        self.assertEqual(self.shop.saved, 1)

    def test_auto_accept_maps_onto_the_field_that_already_exists(self):
        _module.update_quick_flow_settings({"auto_accept_orders": True})
        self.assertEqual(self.shop.get("auto_approve_orders"), 1)

    def test_presets_replace_the_whole_map(self):
        self.shop.set(
            "digit_presets", [_Row({"digit": "9", "product": "PROD-5L"})]
        )
        _module.update_quick_flow_settings(
            {
                "digit_presets": [
                    {"digit": "1", "product": "PROD-5L"},
                    {"digit": "3", "product": {"id": "PROD-20L"}},
                ]
            }
        )
        rows = self.shop.get("digit_presets")
        self.assertEqual(
            [(r["digit"], r["product"]) for r in rows],
            [("1", "PROD-5L"), ("3", "PROD-20L")],
        )

    def test_accepts_a_json_string_body(self):
        _module.update_quick_flow_settings('{"keypad_autodial": true}')
        self.assertEqual(self.shop.get("keypad_autodial"), 1)

    def test_refuses_a_digit_outside_one_to_nine(self):
        for bad in ("0", "10", "", "x"):
            with self.assertRaises(self.frappe.ValidationError):
                _module.update_quick_flow_settings(
                    {"digit_presets": [{"digit": bad, "product": "PROD-5L"}]}
                )

    def test_refuses_the_same_digit_twice(self):
        with self.assertRaises(self.frappe.ValidationError):
            _module.update_quick_flow_settings(
                {
                    "digit_presets": [
                        {"digit": "1", "product": "PROD-5L"},
                        {"digit": "1", "product": "PROD-20L"},
                    ]
                }
            )

    def test_refuses_a_product_that_does_not_exist(self):
        with self.assertRaises(self.frappe.ValidationError):
            _module.update_quick_flow_settings(
                {"digit_presets": [{"digit": "1", "product": "PROD-GHOST"}]}
            )

    def test_refuses_another_shops_product(self):
        with self.assertRaises(self.frappe.ValidationError):
            _module.update_quick_flow_settings(
                {"digit_presets": [{"digit": "1", "product": "PROD-OTHER"}]}
            )

    def test_refuses_a_non_object_body(self):
        with self.assertRaises(self.frappe.ValidationError):
            _module.update_quick_flow_settings("[]")

    def test_clearing_the_map_is_allowed(self):
        self.shop.set(
            "digit_presets", [_Row({"digit": "1", "product": "PROD-5L"})]
        )
        _module.update_quick_flow_settings({"digit_presets": []})
        self.assertEqual(self.shop.get("digit_presets"), [])


if __name__ == "__main__":
    unittest.main()
