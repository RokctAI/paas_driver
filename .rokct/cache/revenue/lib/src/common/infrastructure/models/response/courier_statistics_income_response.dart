// Copyright (c) 2026 RokctAI
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

class CourierStatisticsIncomeResponse {
  CourierStatisticsIncomeResponse({CourierStatisticsModel? data}) {
    _data = data;
  }

  CourierStatisticsIncomeResponse.fromJson(dynamic json) {
    _data =
        json['data'] != null ? CourierStatisticsModel.fromJson(json['data']) : null;
  }

  CourierStatisticsModel? _data;

  CourierStatisticsIncomeResponse copyWith({CourierStatisticsModel? data}) =>
      CourierStatisticsIncomeResponse(data: data ?? _data);

  CourierStatisticsModel? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class CourierStatisticsModel {
  CourierStatisticsModel({
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
  List<CourierChart>? chart;

  CourierStatisticsModel copyWith({
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
    List<CourierChart>? chart,
  }) =>
      CourierStatisticsModel(
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
        chart: chart ?? this.chart,
      );

  factory CourierStatisticsModel.fromJson(Map<String, dynamic> json) =>
      CourierStatisticsModel(
        lastOrderTotalPrice: json["last_order_total_price"],
        lastOrderIncome: json["last_order_income"],
        totalPrice: json["total_price"],
        fmTotalPrice: json["fm_total_price"],
        totalCount: json["total_count"],
        totalNewCount: json["total_new_count"],
        totalReadyCount: json["total_ready_count"],
        totalOnAWayCount: json["total_on_a_way_count"],
        totalAcceptedCount: json["total_accepted_count"],
        totalCanceledCount: json["total_canceled_count"],
        totalDeliveredCount: json["total_delivered_count"],
        totalTodayCount: json["total_today_count"],
        chart: json["chart"] == null
            ? []
            : List<CourierChart>.from(json["chart"]!.map((x) => CourierChart.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "last_order_total_price": lastOrderTotalPrice,
        "last_order_income": lastOrderIncome,
        "total_price": totalPrice,
        "fm_total_price": fmTotalPrice,
        "total_count": totalCount,
        "total_new_count": totalNewCount,
        "total_ready_count": totalReadyCount,
        "total_on_a_way_count": totalOnAWayCount,
        "total_accepted_count": totalAcceptedCount,
        "total_canceled_count": totalCanceledCount,
        "total_delivered_count": totalDeliveredCount,
        "total_today_count": totalTodayCount,
        "chart": chart == null
            ? []
            : List<dynamic>.from(chart!.map((x) => x.toJson())),
      };
}

class CourierChart {
  CourierChart({
    this.time,
    this.totalPrice,
  });

  DateTime? time;
  num? totalPrice;

  CourierChart copyWith({
    DateTime? time,
    num? totalPrice,
  }) =>
      CourierChart(
        time: time ?? this.time,
        totalPrice: totalPrice ?? this.totalPrice,
      );

  factory CourierChart.fromJson(Map<String, dynamic> json) => CourierChart(
        time: json["time"] == null
            ? null
            : DateTime.tryParse(json["time"])?.toLocal(),
        totalPrice: json["total_price"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "time":
            "${time!.year.toString().padLeft(4, '0')}-${time!.month.toString().padLeft(2, '0')}-${time!.day.toString().padLeft(2, '0')}",
        "total_price": totalPrice,
      };
}
