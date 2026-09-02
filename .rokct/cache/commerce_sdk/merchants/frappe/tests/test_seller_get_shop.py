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
Bench-independent tests for seller_shop.get_shop.

Shop.location is a Geolocation field -- a GeoJSON JSON *string* -- but the
client's `ShopData.fromJson` feeds any non-null `location` straight into
`Location.fromJson`, which expects a `{latitude, longitude}` map. The
endpoint must therefore emit the parsed map (or null), and must also carry
the doctype-backed fields the client reads (`price`, `price_per_km`) plus
the review aggregation, without crashing on the `description` field the
Shop doctype does not define.

Runs directly with
`python3 merchants/frappe/tests/test_seller_get_shop.py` -- frappe/paas
are stubbed only when they are not already importable, so this file is
also safe to collect inside a real bench environment.
"""

import json
import sys
import types
import unittest
from pathlib import Path

_SRC = Path(__file__).resolve().parents[1] / "src" / "tenant" / "api"


def _stub_missing_modules():
    """Stub frappe/paas just enough to import the modules under test
    outside a bench. Mirrors test_shop_coords.py."""
    if "frappe" not in sys.modules:
        try:
            import frappe  # noqa: F401
        except ImportError:
            frappe = types.ModuleType("frappe")
            frappe.whitelist = lambda *a, **k: (lambda f: f)
            frappe.db = types.SimpleNamespace(get_value=lambda *a, **k: None)
            model = types.ModuleType("frappe.model")
            document = types.ModuleType("frappe.model.document")
            document.Document = type("Document", (), {})
            frappe.model = model
            sys.modules["frappe"] = frappe
            sys.modules["frappe.model"] = model
            sys.modules["frappe.model.document"] = document

    try:
        import paas.merchants.tenant.api.shop.shop  # noqa: F401
        import paas.base.tenant.api.utils  # noqa: F401
    except ImportError:
        utils = types.ModuleType("paas.base.tenant.api.utils")
        utils._get_seller_shop = lambda user: "SHOP-001"
        utils.api_response = lambda data=None, message=None, status_code=200: {
            "data": data
        }
        idempotency = types.ModuleType("paas.base.tenant.api.idempotency")
        idempotency.idempotent = lambda f: f
        for name in (
            "paas",
            "paas.base",
            "paas.base.tenant",
            "paas.base.tenant.api",
            "paas.merchants",
            "paas.merchants.tenant",
            "paas.merchants.tenant.api",
            "paas.merchants.tenant.api.shop",
        ):
            sys.modules.setdefault(name, types.ModuleType(name))
        sys.modules.setdefault("paas.base.tenant.api.utils", utils)
        sys.modules.setdefault(
            "paas.base.tenant.api.idempotency", idempotency
        )

        # get_shop imports get_shop_coords from the real shop module at
        # call time; exec the compose template ({app_name} substituted,
        # as the composer does) under that dotted name so location
        # parsing is exercised for real.
        shop_path = _SRC / "shop" / "shop.py"
        shop_module = types.ModuleType("paas.merchants.tenant.api.shop.shop")
        shop_module.__file__ = str(shop_path)
        exec(
            compile(
                shop_path.read_text().replace("{app_name}", "paas"),
                str(shop_path),
                "exec",
            ),
            shop_module.__dict__,
        )
        sys.modules.setdefault(
            "paas.merchants.tenant.api.shop.shop", shop_module
        )


_stub_missing_modules()

_SELLER_SHOP_PY = _SRC / "seller_shop" / "seller_shop.py"
_seller_shop_module = types.ModuleType("_seller_shop_under_test")
_seller_shop_module.__file__ = str(_SELLER_SHOP_PY)
exec(
    compile(
        _SELLER_SHOP_PY.read_text().replace("{app_name}", "paas"),
        str(_SELLER_SHOP_PY),
        "exec",
    ),
    _seller_shop_module.__dict__,
)


class _FakeShopDoc:
    """Mimics a Shop document: attribute access for real doctype fields,
    .get() returning None for fields the doctype does not define."""

    def __init__(self, **fields):
        self._fields = fields

    def __getattr__(self, key):
        if key.startswith("_"):
            raise AttributeError(key)
        try:
            return self._fields[key]
        except KeyError:
            raise AttributeError(key)

    def get(self, key, default=None):
        return self._fields.get(key, default)


class _FakeFrappe:
    """Just enough frappe for get_shop, with per-test fixtures."""

    def __init__(self, shop_doc, review_rows=None, review_raises=False):
        self.session = types.SimpleNamespace(user="seller@example.com")
        self.shop_doc = shop_doc
        self.review_rows = review_rows or []
        self.review_raises = review_raises

    def whitelist(self, *args, **kwargs):
        return lambda fn: fn

    def get_doc(self, doctype, name):
        assert doctype == "Shop"
        return self.shop_doc

    def get_all(self, doctype, **kwargs):
        if doctype == "Review":
            if self.review_raises:
                raise Exception("no Review doctype on this tenant")
            return list(self.review_rows)
        return []


def _shop_fields(**overrides):
    fields = {
        "name": "SHOP-001",
        "uuid": "u-1",
        "slug": "test-shop",
        "user": "seller@example.com",
        "tax": 15,
        "service_fee": 2,
        "percentage": 10,
        "phone": "+27110000000",
        "open": 1,
        "visibility": 1,
        "verify": 0,
        "logo": "/files/logo.png",
        "cover_photo": "/files/cover.png",
        "min_amount": 50,
        "price": 20,
        "price_per_km": 7,
        "status": "approved",
        "delivery_time_type": "minute",
        "delivery_time_from": "20",
        "delivery_time_to": "40",
        "location": None,
        "address": "1 Main Rd",
    }
    fields.update(overrides)
    return fields


class TestGetShop(unittest.TestCase):
    def setUp(self):
        self._orig_frappe = _seller_shop_module.frappe

    def tearDown(self):
        _seller_shop_module.frappe = self._orig_frappe

    def _run(self, shop_fields, review_rows=None, review_raises=False):
        _seller_shop_module.frappe = _FakeFrappe(
            _FakeShopDoc(**shop_fields),
            review_rows=review_rows,
            review_raises=review_raises,
        )
        return _seller_shop_module.get_shop()

    def test_geojson_location_becomes_lat_lng_map(self):
        geojson = json.dumps(
            {
                "type": "FeatureCollection",
                "features": [
                    {
                        "type": "Feature",
                        "properties": {},
                        "geometry": {
                            "type": "Point",
                            "coordinates": [28.05, -26.1],  # [lng, lat]
                        },
                    }
                ],
            }
        )
        result = self._run(_shop_fields(location=geojson))
        self.assertEqual(
            result["location"], {"latitude": -26.1, "longitude": 28.05}
        )

    def test_flat_location_string_also_parses(self):
        loc = json.dumps({"latitude": "-23.9", "longitude": "29.46"})
        result = self._run(_shop_fields(location=loc))
        self.assertEqual(
            result["location"], {"latitude": -23.9, "longitude": 29.46}
        )

    def test_unparseable_location_is_null_not_raw_string(self):
        result = self._run(_shop_fields(location="not-json{"))
        self.assertIsNone(result["location"])

    def test_missing_location_is_null(self):
        result = self._run(_shop_fields(location=None))
        self.assertIsNone(result["location"])

    def test_price_fields_are_exposed(self):
        result = self._run(_shop_fields())
        self.assertEqual(result["price"], 20)
        self.assertEqual(result["price_per_km"], 7)

    def test_description_absent_on_doctype_yields_null(self):
        # The Shop doctype defines no `description` field; attribute
        # access would raise, .get() must not.
        result = self._run(_shop_fields())
        self.assertIsNone(result["description"])

    def test_review_aggregation(self):
        result = self._run(
            _shop_fields(),
            review_rows=[{"rating_avg": 4.5, "reviews_count": 7}],
        )
        self.assertEqual(result["rating_avg"], 4.5)
        self.assertEqual(result["reviews_count"], 7)

    def test_review_doctype_missing_degrades_to_zero(self):
        result = self._run(_shop_fields(), review_raises=True)
        self.assertEqual(result["rating_avg"], 0)
        self.assertEqual(result["reviews_count"], 0)


if __name__ == "__main__":
    unittest.main()
