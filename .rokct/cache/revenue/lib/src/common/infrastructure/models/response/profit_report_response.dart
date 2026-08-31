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

/// Models for `api.seller_report.get_seller_profit_report` — the approved
/// revenue dashboard's profitability aggregates (design section 36).
///
/// Hand-written like the sibling `statistics_response.dart` (no codegen) and
/// deliberately tolerant: every field is nullable-parsed with defaults, so a
/// site whose backend predates the endpoint (or answers with a partial map)
/// degrades to zeros instead of a parse crash — the UI's honesty rules
/// (`—` placeholders, the unknown bucket) do the rest.
library;

double _toDouble(dynamic value) =>
    value is num ? value.toDouble() : (double.tryParse('$value') ?? 0.0);

int _toInt(dynamic value) =>
    value is num ? value.toInt() : (int.tryParse('$value') ?? 0);

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// Envelope: Frappe wraps whitelisted return values in `message`; accept the
/// bare map too (the shared Dio stack may already have unwrapped it).
class ProfitReportResponse {
  final ProfitReport? data;

  ProfitReportResponse({this.data});

  factory ProfitReportResponse.fromJson(dynamic json) {
    final dynamic payload =
        json is Map ? (json['message'] ?? json['data'] ?? json) : json;
    return ProfitReportResponse(
      data: payload is Map ? ProfitReport.fromJson(_asMap(payload)) : null,
    );
  }
}

/// The whole report: totals / unknown bucket / series / products / status
/// split — one window, one shop (the backend scopes by `_get_seller_shop`).
class ProfitReport {
  final ProfitTotals totals;
  final UnknownCostBucket unknownBucket;
  final List<ProfitPoint> series;
  final List<ProductProfit> products;

  /// Split-bar wire vocabulary: new / accepted / cooking / on_a_way /
  /// delivered / cancelled.
  final Map<String, int> statusCounts;

  const ProfitReport({
    required this.totals,
    required this.unknownBucket,
    required this.series,
    required this.products,
    required this.statusCounts,
  });

  factory ProfitReport.fromJson(Map<String, dynamic> json) => ProfitReport(
        totals: ProfitTotals.fromJson(_asMap(json['totals'])),
        unknownBucket:
            UnknownCostBucket.fromJson(_asMap(json['unknown_bucket'])),
        series: (json['series'] is List)
            ? (json['series'] as List)
                .map((e) => ProfitPoint.fromJson(_asMap(e)))
                .toList()
            : const [],
        products: (json['products'] is List)
            ? (json['products'] as List)
                .map((e) => ProductProfit.fromJson(_asMap(e)))
                .toList()
            : const [],
        statusCounts: _asMap(json['status_counts'])
            .map((key, value) => MapEntry(key, _toInt(value))),
      );
}

/// The KPI plane's numbers. `marginPct` is a percentage of COSTED revenue
/// only — uncosted lines can never flatter it (the approved honesty rule).
class ProfitTotals {
  final double revenue;
  final double profit;
  final double costedRevenue;
  final double marginPct;
  final int orders;

  /// Orders whose every line carries a positive cost snapshot — the
  /// "183 of 214 orders costed" sub-line.
  final int ordersCosted;
  final double avgOrder;

  const ProfitTotals({
    this.revenue = 0,
    this.profit = 0,
    this.costedRevenue = 0,
    this.marginPct = 0,
    this.orders = 0,
    this.ordersCosted = 0,
    this.avgOrder = 0,
  });

  factory ProfitTotals.fromJson(Map<String, dynamic> json) => ProfitTotals(
        revenue: _toDouble(json['revenue']),
        profit: _toDouble(json['profit']),
        costedRevenue: _toDouble(json['costed_revenue']),
        marginPct: _toDouble(json['margin_pct']),
        orders: _toInt(json['orders']),
        ordersCosted: _toInt(json['orders_costed']),
        avgOrder: _toDouble(json['avg_order']),
      );
}

/// Orders whose profit is UNKNOWN — at least one line sold without a cost
/// snapshot (`cost_price <= 0`, including pre-cost-field orders). Their
/// revenue is named and excluded, never silently counted as pure profit.
class UnknownCostBucket {
  final int orders;
  final double revenueExcluded;

  const UnknownCostBucket({this.orders = 0, this.revenueExcluded = 0});

  factory UnknownCostBucket.fromJson(Map<String, dynamic> json) =>
      UnknownCostBucket(
        orders: _toInt(json['orders']),
        revenueExcluded: _toDouble(json['revenue_excluded']),
      );

  bool get isEmpty => orders == 0 && revenueExcluded == 0;
}

/// One trend-chart bucket: a day (`2026-08-24`) or, in the Today view, an
/// hour of the single requested day (`09:00`).
class ProfitPoint {
  final String date;
  final double revenue;
  final double profit;

  const ProfitPoint({this.date = '', this.revenue = 0, this.profit = 0});

  factory ProfitPoint.fromJson(Map<String, dynamic> json) => ProfitPoint(
        date: '${json['date'] ?? ''}',
        revenue: _toDouble(json['revenue']),
        profit: _toDouble(json['profit']),
      );
}

/// One Profit-by-product row. `price`/`cost` are the product's CURRENT
/// values (they feed the 35a Price/Cost/Margin strip); `profit`/`marginPct`
/// stay snapshot-based over the window's costed lines. `costMissing` drives
/// the approved "cost not set" row state (grey cost, `—` profit/margin).
class ProductProfit {
  final String id;
  final String name;
  final int sold;
  final double revenue;
  final double price;
  final double cost;
  final double profit;
  final double marginPct;
  final bool costMissing;

  const ProductProfit({
    this.id = '',
    this.name = '',
    this.sold = 0,
    this.revenue = 0,
    this.price = 0,
    this.cost = 0,
    this.profit = 0,
    this.marginPct = 0,
    this.costMissing = false,
  });

  factory ProductProfit.fromJson(Map<String, dynamic> json) => ProductProfit(
        id: '${json['product'] ?? ''}',
        name: '${json['name'] ?? json['product'] ?? ''}',
        sold: _toInt(json['sold']),
        revenue: _toDouble(json['revenue']),
        price: _toDouble(json['price']),
        cost: _toDouble(json['cost']),
        profit: _toDouble(json['profit']),
        marginPct: _toDouble(json['margin_pct']),
        costMissing: json['cost_missing'] == true || json['cost_missing'] == 1,
      );
}
