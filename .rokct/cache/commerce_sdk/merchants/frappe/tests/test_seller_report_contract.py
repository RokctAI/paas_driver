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
Bench-independent tests for the seller income statistics contract.

`get_order_report` must return the aggregate `StatisticsModel` map the
revenue client parses (totals, unmerged per-status counters, daily
`chart` series) and `get_order_report_paginate` the legacy
`StatisticsOrder` row shape -- not the bare Order lists both endpoints
used to emit (revenue_sdk `docs/frappe-endpoint-contract.md`).

Runs directly with
`python3 merchants/frappe/tests/test_seller_report_contract.py` --
frappe/paas are stubbed with fakes local to the module under test, so this
file is also safe to collect inside a real bench environment.
"""

import sys
import types
import unittest
from datetime import date, datetime
from pathlib import Path


class _dict(dict):
    """Attribute-access dict, like frappe._dict."""

    def __getattr__(self, key):
        return self.get(key)


class _FakeUtils:
    @staticmethod
    def today():
        return "2026-08-28"

    @staticmethod
    def add_months(day, months):
        # Only the (-1 month) default window is exercised.
        return "2026-07-28"

    @staticmethod
    def getdate(value):
        if isinstance(value, datetime):
            return value.date()
        if isinstance(value, date):
            return value
        return date.fromisoformat(str(value)[:10])

    @staticmethod
    def flt(value):
        try:
            return float(value or 0)
        except (TypeError, ValueError):
            return 0.0

    @staticmethod
    def cint(value):
        try:
            return int(value or 0)
        except (TypeError, ValueError):
            return 0


class _FakeFrappe(types.ModuleType):
    """Just enough frappe for seller_report.py, dispatching get_all by
    doctype from per-test fixtures."""

    def __init__(self):
        super().__init__("frappe")
        self.utils = _FakeUtils()
        self.session = types.SimpleNamespace(user="seller@example.com")
        self.rows = {}
        self.calls = []

    def whitelist(self, *args, **kwargs):
        return lambda fn: fn

    def get_all(self, doctype, **kwargs):
        self.calls.append((doctype, kwargs))
        return [_dict(r) for r in self.rows.get(doctype, [])]


def _load_module(fake_frappe):
    """Exec the seller_report.py compose template against the fakes.

    src files are compose templates: the composer textually substitutes
    {app_name} with the target app's package name when copying them into
    an app, so mirror that substitution here before executing.
    """
    utils_mod = types.ModuleType("paas.base.tenant.api.utils")
    utils_mod._get_seller_shop = lambda user: "SHOP-001"

    path = (
        Path(__file__).resolve().parents[1]
        / "src" / "tenant" / "api" / "seller_report" / "seller_report.py"
    )
    module = types.ModuleType("_seller_report_under_test")
    module.__file__ = str(path)

    saved = {
        name: sys.modules.get(name)
        for name in ("frappe", "paas.base.tenant.api.utils")
    }
    sys.modules["frappe"] = fake_frappe
    sys.modules["paas.base.tenant.api.utils"] = utils_mod
    try:
        exec(
            compile(
                path.read_text().replace("{app_name}", "paas"),
                str(path),
                "exec",
            ),
            module.__dict__,
        )
    finally:
        for name, mod in saved.items():
            if mod is None:
                sys.modules.pop(name, None)
            else:
                sys.modules[name] = mod
    # The module keeps its own binding to the fake regardless of
    # sys.modules restoration above.
    module.frappe = fake_frappe
    return module


class TestGetOrderReport(unittest.TestCase):
    def _run(self, orders, **kwargs):
        fake = _FakeFrappe()
        fake.rows["Order"] = orders
        module = _load_module(fake)
        return module.get_order_report(**kwargs), fake

    def test_statistics_map_shape_and_totals(self):
        orders = [
            # newest first, as the endpoint orders by creation desc
            {"name": "o6", "total_price": 50, "commission_fee": 5,
             "status": "New", "creation": "2026-08-28 09:00:00"},
            {"name": "o5", "total_price": 200, "commission_fee": 20,
             "status": "Delivered", "creation": "2026-08-28 08:00:00"},
            {"name": "o4", "total_price": 100, "commission_fee": 10,
             "status": "Delivered", "creation": "2026-08-27 12:00:00"},
            {"name": "o3", "total_price": 80, "commission_fee": 0,
             "status": "Shipped", "creation": "2026-08-27 11:00:00"},
            {"name": "o2", "total_price": 60, "commission_fee": 0,
             "status": "Accepted", "creation": "2026-08-26 10:00:00"},
            {"name": "o1", "total_price": 40, "commission_fee": 0,
             "status": "Cancelled", "creation": "2026-08-26 09:00:00"},
        ]
        result, _ = self._run(
            orders, from_date="2026-08-01", to_date="2026-08-28"
        )

        self.assertEqual(result["total_count"], 6)
        self.assertEqual(result["total_today_count"], 2)
        self.assertEqual(result["total_new_count"], 1)
        self.assertEqual(result["total_accepted_count"], 1)
        self.assertEqual(result["total_on_a_way_count"], 1)
        self.assertEqual(result["total_delivered_count"], 2)
        self.assertEqual(result["total_canceled_count"], 1)
        self.assertEqual(result["total_ready_count"], 0)

        # Monetary aggregates cover Delivered orders only.
        self.assertEqual(result["total_price"], 300)
        self.assertEqual(result["fm_total_price"], 270)

        # Last-order row reflects the newest order in the window.
        self.assertEqual(result["last_order_total_price"], 50)
        self.assertEqual(result["last_order_income"], 45)

        # Daily chart of delivered revenue, ascending by day.
        self.assertEqual(
            result["chart"],
            [
                {"time": "2026-08-27", "total_price": 100},
                {"time": "2026-08-28", "total_price": 200},
            ],
        )

    def test_no_merged_progress_counter_keys(self):
        # The legacy dashboard needs per-status tiles; the collapsed
        # `progress_orders_count` shape must not come back.
        result, _ = self._run(
            [], from_date="2026-08-01", to_date="2026-08-28"
        )
        self.assertNotIn("progress_orders_count", result)
        for key in (
            "total_price",
            "fm_total_price",
            "total_count",
            "total_new_count",
            "total_accepted_count",
            "total_ready_count",
            "total_on_a_way_count",
            "total_delivered_count",
            "total_canceled_count",
            "total_today_count",
            "chart",
        ):
            self.assertIn(key, result)

    def test_empty_window_is_zeros(self):
        result, _ = self._run(
            [], from_date="2026-08-01", to_date="2026-08-28"
        )
        self.assertEqual(result["total_count"], 0)
        self.assertEqual(result["total_price"], 0)
        self.assertEqual(result["chart"], [])
        self.assertEqual(result["last_order_total_price"], 0)

    def test_defaults_window_when_dates_missing(self):
        _, fake = self._run([])
        doctype, kwargs = fake.calls[0]
        self.assertEqual(doctype, "Order")
        self.assertEqual(
            kwargs["filters"]["creation"],
            ["between", ["2026-07-28", "2026-08-28"]],
        )


class TestGetOrderReportPaginate(unittest.TestCase):
    def _fake(self):
        fake = _FakeFrappe()
        fake.rows["Order"] = [
            {"name": "1042", "user": "buyer@example.com",
             "total_price": 150.5, "status": "Delivered",
             "creation": "2026-08-27 12:00:00"},
            {"name": "a1b2c3", "user": None, "total_price": 90,
             "status": "New", "creation": "2026-08-26 12:00:00"},
        ]
        fake.rows["User"] = [
            {"name": "buyer@example.com", "first_name": "Thabo",
             "last_name": "Mokoena"},
        ]
        fake.rows["Order Item"] = [
            {"parent": "1042", "product": "PROD-1", "quantity": 2},
            {"parent": "1042", "product": "PROD-2", "quantity": 1},
            {"parent": "a1b2c3", "product": "PROD-1", "quantity": 4},
        ]
        fake.rows["Product"] = [
            {"name": "PROD-1", "title": "Rooibos Tea"},
            {"name": "PROD-2", "title": "Honey"},
        ]
        return fake

    def test_row_shape(self):
        fake = self._fake()
        module = _load_module(fake)
        result = module.get_order_report_paginate(
            from_date="2026-08-01", to_date="2026-08-28"
        )

        self.assertIn("data", result)
        rows = result["data"]
        self.assertEqual(len(rows), 2)

        first = rows[0]
        self.assertEqual(first["id"], 1042)  # numeric names become int
        self.assertEqual(first["status"], "Delivered")
        self.assertEqual(first["firstname"], "Thabo")
        self.assertEqual(first["lastname"], "Mokoena")
        self.assertEqual(first["active"], 1)
        self.assertEqual(first["quantity"], 3)
        self.assertEqual(first["price"], 150.5)
        self.assertEqual(first["products"], ["Rooibos Tea", "Honey"])

        second = rows[1]
        # Hash-style Order names cannot be sent as `id`: the client field
        # is typed int and a string would break the whole parse.
        self.assertIsNone(second["id"])
        self.assertIsNone(second["firstname"])
        self.assertEqual(second["quantity"], 4)
        self.assertEqual(second["products"], ["Rooibos Tea"])

    def test_page_per_page_pagination(self):
        fake = self._fake()
        module = _load_module(fake)
        module.get_order_report_paginate(page=3, per_page=10)
        doctype, kwargs = fake.calls[0]
        self.assertEqual(doctype, "Order")
        self.assertEqual(kwargs["offset"], 20)
        self.assertEqual(kwargs["limit"], 10)

    def test_legacy_limit_params_still_work(self):
        fake = self._fake()
        module = _load_module(fake)
        module.get_order_report_paginate(
            limit_start=40, limit_page_length=5
        )
        _, kwargs = fake.calls[0]
        self.assertEqual(kwargs["offset"], 40)
        self.assertEqual(kwargs["limit"], 5)

    def test_no_date_window_means_no_creation_filter(self):
        fake = self._fake()
        module = _load_module(fake)
        module.get_order_report_paginate()
        _, kwargs = fake.calls[0]
        self.assertNotIn("creation", kwargs["filters"])
        self.assertEqual(kwargs["filters"]["shop"], "SHOP-001")


class TestGetSellerProfitReport(unittest.TestCase):
    """The profitability aggregates behind the approved revenue dashboard
    (section 36): profit strictly from the cost_price snapshots frozen at
    sale, cost_price <= 0 lines into the unknown bucket (never free / 100%
    margin), margin over COSTED revenue only."""

    def _fake(self):
        fake = _FakeFrappe()
        fake.rows["Order"] = [
            # Fully costed order, two lines, delivered today.
            {"name": "o1", "status": "Delivered",
             "creation": "2026-08-28 09:00:00"},
            # Order with one costed and one UNCOSTED line, the day before.
            {"name": "o2", "status": "Shipped",
             "creation": "2026-08-27 12:00:00"},
            # Order with NO lines at all — never costed.
            {"name": "o3", "status": "Cancelled",
             "creation": "2026-08-27 08:00:00"},
        ]
        fake.rows["Order Item"] = [
            # o1: 2 x (price 50, cost 30) -> revenue 100, profit 40
            {"parent": "o1", "product": "PROD-A", "quantity": 2,
             "price": 50, "cost_price": 30},
            # o1: 1 x (price 20, cost 10) -> revenue 20, profit 10
            {"parent": "o1", "product": "PROD-B", "quantity": 1,
             "price": 20, "cost_price": 10},
            # o2: 1 x (price 80, cost 48) -> revenue 80, profit 32
            {"parent": "o2", "product": "PROD-A", "quantity": 1,
             "price": 80, "cost_price": 48},
            # o2: 3 x (price 30, cost 0 -> UNKNOWN) -> revenue 90 excluded
            {"parent": "o2", "product": "PROD-C", "quantity": 3,
             "price": 30, "cost_price": 0},
        ]
        fake.rows["Product"] = [
            {"name": "PROD-A", "title": "Beef Kota", "price": 50, "cost": 30},
            {"name": "PROD-B", "title": "Honey", "price": 20, "cost": 10},
            # Current cost unset -> cost_missing row.
            {"name": "PROD-C", "title": "Chips (large)", "price": 30,
             "cost": 0},
        ]
        return fake

    def _run(self, **kwargs):
        fake = self._fake()
        module = _load_module(fake)
        return module.get_seller_profit_report(**kwargs), fake

    def test_totals_and_margin_over_costed_revenue_only(self):
        result, _ = self._run(from_date="2026-08-01", to_date="2026-08-28")
        totals = result["totals"]
        # revenue counts EVERY line: 100 + 20 + 80 + 90
        self.assertEqual(totals["revenue"], 290)
        # profit only from costed lines: 40 + 10 + 32
        self.assertEqual(totals["profit"], 82)
        # margin denominator excludes the uncosted 90
        self.assertEqual(totals["costed_revenue"], 200)
        self.assertAlmostEqual(totals["margin_pct"], 41.0)
        self.assertEqual(totals["orders"], 3)
        # only o1 has every line costed; o2 has an uncosted line and o3
        # has no lines
        self.assertEqual(totals["orders_costed"], 1)
        self.assertAlmostEqual(totals["avg_order"], 290 / 3)

    def test_unknown_bucket_never_counts_as_profit(self):
        result, _ = self._run(from_date="2026-08-01", to_date="2026-08-28")
        bucket = result["unknown_bucket"]
        # o2 (uncosted line) + o3 (no lines): orders_costed + unknown ==
        # orders
        self.assertEqual(bucket["orders"], 2)
        self.assertEqual(bucket["revenue_excluded"], 90)
        self.assertEqual(
            result["totals"]["orders_costed"] + bucket["orders"],
            result["totals"]["orders"],
        )

    def test_series_daily_ascending_with_profit_line(self):
        result, _ = self._run(from_date="2026-08-01", to_date="2026-08-28")
        self.assertEqual(
            result["series"],
            [
                {"date": "2026-08-27", "revenue": 170, "profit": 32},
                {"date": "2026-08-28", "revenue": 120, "profit": 50},
            ],
        )

    def test_series_hourly_when_single_day_window(self):
        fake = self._fake()
        # Narrow the fixtures to one day so from == to is coherent.
        fake.rows["Order"] = [
            {"name": "o1", "status": "Delivered",
             "creation": "2026-08-28 09:15:00"},
        ]
        fake.rows["Order Item"] = [
            {"parent": "o1", "product": "PROD-A", "quantity": 1,
             "price": 50, "cost_price": 30},
        ]
        module = _load_module(fake)
        result = module.get_seller_profit_report(
            from_date="2026-08-28", to_date="2026-08-28"
        )
        self.assertEqual(
            result["series"],
            [{"date": "09:00", "revenue": 50, "profit": 20}],
        )

    def test_products_sorted_profit_desc_cost_missing_last(self):
        result, _ = self._run(from_date="2026-08-01", to_date="2026-08-28")
        rows = result["products"]
        self.assertEqual(
            [r["product"] for r in rows], ["PROD-A", "PROD-B", "PROD-C"]
        )
        first = rows[0]
        # PROD-A: 2@(50-30) + 1@(80-48) -> profit 72 over 180 revenue
        self.assertEqual(first["name"], "Beef Kota")
        self.assertEqual(first["sold"], 3)
        self.assertEqual(first["revenue"], 180)
        self.assertEqual(first["profit"], 72)
        self.assertAlmostEqual(first["margin_pct"], 40.0)
        self.assertFalse(first["cost_missing"])
        # Current price/cost ride along for the strip.
        self.assertEqual(first["price"], 50)
        self.assertEqual(first["cost"], 30)

        chips = rows[2]
        self.assertTrue(chips["cost_missing"])
        self.assertEqual(chips["profit"], 0)
        self.assertEqual(chips["revenue"], 90)

    def test_status_counts_wire_vocabulary(self):
        result, _ = self._run(from_date="2026-08-01", to_date="2026-08-28")
        self.assertEqual(
            result["status_counts"],
            {
                "new": 0,
                "accepted": 0,
                "cooking": 0,
                "on_a_way": 1,
                "delivered": 1,
                "cancelled": 1,
            },
        )

    def test_shop_scoped_window_filters(self):
        _, fake = self._run(from_date="2026-08-01", to_date="2026-08-28")
        doctype, kwargs = fake.calls[0]
        self.assertEqual(doctype, "Order")
        self.assertEqual(kwargs["filters"]["shop"], "SHOP-001")
        self.assertEqual(
            kwargs["filters"]["creation"],
            ["between", ["2026-08-01", "2026-08-28"]],
        )

    def test_empty_window_is_zeros(self):
        fake = _FakeFrappe()
        module = _load_module(fake)
        result = module.get_seller_profit_report(
            from_date="2026-08-01", to_date="2026-08-28"
        )
        self.assertEqual(result["totals"]["revenue"], 0.0)
        self.assertEqual(result["totals"]["margin_pct"], 0.0)
        self.assertEqual(result["totals"]["avg_order"], 0.0)
        self.assertEqual(result["unknown_bucket"]["orders"], 0)
        self.assertEqual(result["series"], [])
        self.assertEqual(result["products"], [])


if __name__ == "__main__":
    unittest.main()
