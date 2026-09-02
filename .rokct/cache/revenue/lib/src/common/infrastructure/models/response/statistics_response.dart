// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

/// Seller order-report statistics.
///
/// Ported unchanged from `paas_manager`'s `StatisticsResponse` — the Dart side
/// was already complete; only the server answering the URL differs. This is the
/// shape the income page consumes, and therefore the contract the Frappe
/// endpoint must satisfy (see `docs/frappe-endpoint-contract.md`).
library;

class StatisticsResponse {
  StatisticsResponse({StatisticsModel? data}) {
    _data = data;
  }

  StatisticsResponse.fromJson(dynamic json) {
    // Frappe wraps whitelisted return values in `message`; the legacy shape
    // used `data`. Accept either so the client is not the thing that breaks
    // when the endpoint lands.
    final payload = (json is Map<String, dynamic>)
        ? (json['message'] ?? json['data'])
        : null;
    _data = payload != null
        ? StatisticsModel.fromJson(Map<String, dynamic>.from(payload as Map))
        : null;
  }

  StatisticsModel? _data;

  StatisticsResponse copyWith({StatisticsModel? data}) =>
      StatisticsResponse(data: data ?? _data);

  StatisticsModel? get data => _data;

  Map<String, dynamic> toJson() => {
        if (_data != null) 'data': _data?.toJson(),
      };
}

class StatisticsModel {
  StatisticsModel({
    this.lastOrderTotalPrice,
    this.lastOrderIncome,
    this.totalPrice,
    this.fmTotalPrice,
    this.totalCount,
    this.totalNewCount,
    this.totalReadyCount,
    this.totalOnAWayCount,
    this.totalAcceptedCount,
    this.totalCanceledCount,
    this.totalDeliveredCount,
    this.totalTodayCount,
    this.chart,
  });

  num? lastOrderTotalPrice;
  num? lastOrderIncome;
  num? totalPrice;
  num? fmTotalPrice;
  int? totalCount;
  int? totalNewCount;
  int? totalReadyCount;
  int? totalOnAWayCount;
  int? totalAcceptedCount;
  int? totalCanceledCount;
  int? totalDeliveredCount;
  int? totalTodayCount;
  List<Chart>? chart;

  StatisticsModel copyWith({
    num? lastOrderTotalPrice,
    num? lastOrderIncome,
    num? totalPrice,
    num? fmTotalPrice,
    int? totalCount,
    int? totalNewCount,
    int? totalReadyCount,
    int? totalOnAWayCount,
    int? totalAcceptedCount,
    int? totalCanceledCount,
    int? totalDeliveredCount,
    int? totalTodayCount,
    List<Chart>? chart,
  }) =>
      StatisticsModel(
        lastOrderTotalPrice: lastOrderTotalPrice ?? this.lastOrderTotalPrice,
        lastOrderIncome: lastOrderIncome ?? this.lastOrderIncome,
        totalPrice: totalPrice ?? this.totalPrice,
        fmTotalPrice: fmTotalPrice ?? this.fmTotalPrice,
        totalCount: totalCount ?? this.totalCount,
        totalNewCount: totalNewCount ?? this.totalNewCount,
        totalReadyCount: totalReadyCount ?? this.totalReadyCount,
        totalOnAWayCount: totalOnAWayCount ?? this.totalOnAWayCount,
        totalAcceptedCount: totalAcceptedCount ?? this.totalAcceptedCount,
        totalCanceledCount: totalCanceledCount ?? this.totalCanceledCount,
        totalDeliveredCount: totalDeliveredCount ?? this.totalDeliveredCount,
        totalTodayCount: totalTodayCount ?? this.totalTodayCount,
        chart: chart ?? this.chart,
      );

  factory StatisticsModel.fromJson(Map<String, dynamic> json) =>
      StatisticsModel(
        lastOrderTotalPrice: json['last_order_total_price'],
        lastOrderIncome: json['last_order_income'],
        totalPrice: json['total_price'],
        fmTotalPrice: json['fm_total_price'],
        totalCount: json['total_count'],
        totalNewCount: json['total_new_count'],
        totalReadyCount: json['total_ready_count'],
        totalOnAWayCount: json['total_on_a_way_count'],
        totalAcceptedCount: json['total_accepted_count'],
        totalCanceledCount: json['total_canceled_count'],
        totalDeliveredCount: json['total_delivered_count'],
        totalTodayCount: json['total_today_count'],
        chart: json['chart'] == null
            ? []
            : List<Chart>.from(
                (json['chart'] as List).map(
                  (x) => Chart.fromJson(Map<String, dynamic>.from(x as Map)),
                ),
              ),
      );

  Map<String, dynamic> toJson() => {
        'last_order_total_price': lastOrderTotalPrice,
        'last_order_income': lastOrderIncome,
        'total_price': totalPrice,
        'fm_total_price': fmTotalPrice,
        'total_count': totalCount,
        'total_new_count': totalNewCount,
        'total_ready_count': totalReadyCount,
        'total_on_a_way_count': totalOnAWayCount,
        'total_accepted_count': totalAcceptedCount,
        'total_canceled_count': totalCanceledCount,
        'total_delivered_count': totalDeliveredCount,
        'total_today_count': totalTodayCount,
        'chart': chart == null
            ? []
            : List<dynamic>.from(chart!.map((x) => x.toJson())),
      };
}

class Chart {
  Chart({this.time, this.totalPrice});

  DateTime? time;
  num? totalPrice;

  Chart copyWith({DateTime? time, num? totalPrice}) => Chart(
        time: time ?? this.time,
        totalPrice: totalPrice ?? this.totalPrice,
      );

  factory Chart.fromJson(Map<String, dynamic> json) => Chart(
        time: json['time'] == null
            ? null
            : DateTime.tryParse('${json['time']}')?.toLocal() ?? DateTime.now(),
        totalPrice: json['total_price']?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'time': time == null
            ? null
            : '${time!.year.toString().padLeft(4, '0')}-'
                '${time!.month.toString().padLeft(2, '0')}-'
                '${time!.day.toString().padLeft(2, '0')}',
        'total_price': totalPrice,
      };
}

/// Y-axis interpolation helper for the income page's sales chart.
///
/// Ported from `paas_manager`'s legacy `FindPriceIndex` extension
/// (`lib/infrastructure/services/extension.dart`), which operated on the
/// host's retired `Chart` model. It lives here now so the manager income
/// chart template resolves it against this SDK's [Chart] instead.
extension StatisticsPriceIndex on List<num> {
  /// Maps [price] onto a fractional index within this sorted axis-label
  /// list, interpolating between the two nearest label values.
  double findPriceIndex(num price) {
    if (price != 0) {
      int startIndex = 0;
      int endIndex = 0;
      for (int i = 0; i < length; i++) {
        if (this[i] >= price.toInt()) {
          startIndex = i;
          break;
        }
      }
      for (int i = 0; i < length; i++) {
        if (this[i] <= price) {
          endIndex = i;
        }
      }
      if (startIndex == endIndex) {
        return length.toDouble();
      }

      final num a = this[startIndex] - this[endIndex];
      final num b = price - this[endIndex];
      final num c = b / a;
      return startIndex.toDouble() + c;
    } else {
      return 0;
    }
  }
}

/// Point-lookup helpers for the income page's sales chart, ported from the
/// same legacy extension file as [StatisticsPriceIndex]. The legacy versions
/// leaned on a host `DateTime.toEqualTime(WithHour)` extension; the date
/// comparison is inlined here so the SDK carries no host dependency.
extension StatisticsChartLookup on List<Chart> {
  /// Total price of the chart point on the same calendar day as [time].
  num findPrice(DateTime time) {
    num price = 0;
    for (final point in this) {
      final t = point.time;
      if (t != null &&
          t.year == time.year &&
          t.month == time.month &&
          t.day == time.day) {
        price = point.totalPrice ?? 0;
      }
    }
    return price;
  }

  /// Same-day lookup as [findPrice], additionally matching the hour.
  num findPriceWithHour(DateTime time) {
    num price = 0;
    for (final point in this) {
      final t = point.time;
      if (t != null &&
          t.year == time.year &&
          t.month == time.month &&
          t.day == time.day &&
          t.hour == time.hour) {
        price = point.totalPrice ?? 0;
      }
    }
    return price;
  }
}
