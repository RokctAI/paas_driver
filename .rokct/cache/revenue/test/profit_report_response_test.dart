// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Parsing of the get_seller_profit_report contract — including the honesty
// rules the approved design hangs on the data: the unknown bucket, the
// cost_missing row state, and tolerant parsing so a partial or missing map
// degrades to zeros rather than a crash.

import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/profit_report_response.dart';

void main() {
  final Map<String, dynamic> payload = {
    'totals': {
      'revenue': 15608.0,
      'profit': 5544.0,
      'costed_revenue': 13388.0,
      'margin_pct': 41.4,
      'orders': 214,
      'orders_costed': 183,
      'avg_order': 72.93,
    },
    'unknown_bucket': {'orders': 31, 'revenue_excluded': 2220.0},
    'series': [
      {'date': '2026-08-24', 'revenue': 2000, 'profit': 700},
      {'date': '2026-08-25', 'revenue': 2200.5, 'profit': 800.5},
    ],
    'products': [
      {
        'product': 'PRD-0001',
        'name': 'Beef Kota',
        'sold': 96,
        'revenue': 4320.0,
        'price': 45.0,
        'cost': 26.0,
        'profit': 1824.0,
        'margin_pct': 42.2,
        'cost_missing': false,
      },
      {
        'product': 'PRD-0002',
        'name': 'Chips (large)',
        'sold': 74,
        'revenue': 2220.0,
        'price': 30.0,
        'cost': 0,
        'profit': 0,
        'margin_pct': 0,
        'cost_missing': true,
      },
    ],
    'status_counts': {
      'new': 14,
      'accepted': 0,
      'cooking': 21,
      'on_a_way': 18,
      'delivered': 152,
      'cancelled': 9,
    },
  };

  test('parses the frappe message envelope', () {
    final response = ProfitReportResponse.fromJson({'message': payload});
    final report = response.data!;
    expect(report.totals.revenue, 15608.0);
    expect(report.totals.ordersCosted, 183);
    expect(report.unknownBucket.orders, 31);
    expect(report.series, hasLength(2));
    expect(report.products.first.name, 'Beef Kota');
    expect(report.statusCounts['delivered'], 152);
  });

  test('parses a bare (pre-unwrapped) map identically', () {
    final report = ProfitReportResponse.fromJson(payload).data!;
    expect(report.totals.marginPct, 41.4);
    expect(report.unknownBucket.revenueExcluded, 2220.0);
  });

  test('cost_missing drives the "cost not set" row state — never a margin',
      () {
    final report = ProfitReportResponse.fromJson(payload).data!;
    final chips = report.products[1];
    expect(chips.costMissing, isTrue);
    expect(chips.profit, 0);
    // The revenue is still named — excluded, not vanished.
    expect(chips.revenue, 2220.0);
  });

  test('unknown bucket accounts for every non-costed order', () {
    final report = ProfitReportResponse.fromJson(payload).data!;
    expect(
      report.totals.ordersCosted + report.unknownBucket.orders,
      report.totals.orders,
    );
    expect(report.unknownBucket.isEmpty, isFalse);
    expect(const UnknownCostBucket().isEmpty, isTrue);
  });

  test('a partial or empty map degrades to zeros, not a crash', () {
    final empty = ProfitReportResponse.fromJson({'message': {}}).data!;
    expect(empty.totals.revenue, 0);
    expect(empty.totals.orders, 0);
    expect(empty.unknownBucket.isEmpty, isTrue);
    expect(empty.series, isEmpty);
    expect(empty.products, isEmpty);
    expect(empty.statusCounts, isEmpty);

    // Numbers arriving as strings (Frappe flt edge) still parse.
    final stringy = ProfitReportResponse.fromJson({
      'totals': {'revenue': '12.5', 'orders': '3'},
    }).data!;
    expect(stringy.totals.revenue, 12.5);
    expect(stringy.totals.orders, 3);

    // A non-map answer yields no report — the UI's error state.
    expect(ProfitReportResponse.fromJson(null).data, isNull);
    expect(ProfitReportResponse.fromJson('nope').data, isNull);
  });
}
