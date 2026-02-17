class StatisticsIncomeResponse {
  StatisticsIncomeResponse({StatisticsModel? data}) {
    _data = data;
  }

  StatisticsIncomeResponse.fromJson(dynamic json) {
    _data = json['data'] != null
        ? StatisticsModel.fromJson(json['data'])
        : null;
  }

  StatisticsModel? _data;

  StatisticsIncomeResponse copyWith({StatisticsModel? data}) =>
      StatisticsIncomeResponse(data: data ?? _data);

  StatisticsModel? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
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
        chart: chart ?? this.chart,
      );

  factory StatisticsModel.fromJson(Map<String, dynamic> json) => StatisticsModel(
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
    chart: json["chart"] == null ? [] : List<Chart>.from(json["chart"]!.map((x) => Chart.fromJson(x))),
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
    "chart": chart == null ? [] : List<dynamic>.from(chart!.map((x) => x.toJson())),
  };
}

class Chart {
  Chart({
    this.time,
    this.totalPrice,
  });

  DateTime? time;
  num? totalPrice;

  Chart copyWith({
    DateTime? time,
    num? totalPrice,
  }) =>
      Chart(
        time: time ?? this.time,
        totalPrice: totalPrice ?? this.totalPrice,
      );

  factory Chart.fromJson(Map<String, dynamic> json) => Chart(
    time: json["time"] == null ? null : DateTime.tryParse(json["time"])?.toLocal(),
    totalPrice: json["total_price"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "time": "${time!.year.toString().padLeft(4, '0')}-${time!.month.toString().padLeft(2, '0')}-${time!.day.toString().padLeft(2, '0')}",
    "total_price": totalPrice,
  };
}

