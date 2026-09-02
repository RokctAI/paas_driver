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

class CourierStatisticsResponse {
  CourierStatisticsResponse({
    this.timestamp,
    this.status,
    this.message,
    this.data,
  });

  CourierStatisticsResponse.fromJson(dynamic json) {
    timestamp = json['timestamp'];
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? CourierStatisticsData.fromJson(json['data']) : null;
  }

  String? timestamp;
  bool? status;
  String? message;
  CourierStatisticsData? data;

  CourierStatisticsResponse copyWith({
    String? timestamp,
    bool? status,
    String? message,
    CourierStatisticsData? data,
  }) =>
      CourierStatisticsResponse(
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['timestamp'] = timestamp;
    map['status'] = status;
    map['message'] = message;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }
}

class CourierStatisticsData {
  CourierStatisticsData({
    this.progressOrdersCount,
    this.deliveredOrdersCount,
    this.cancelOrdersCount,
    this.newOrdersCount,
    this.acceptedOrdersCount,
    this.readyOrdersCount,
    this.onAWayOrdersCount,
    this.ordersCount,
    this.totalPrice,
  });

  CourierStatisticsData.fromJson(dynamic json) {
    progressOrdersCount = json['progress_orders_count'];
    deliveredOrdersCount = json['delivered_orders_count'];
    cancelOrdersCount = json['cancel_orders_count'];
    newOrdersCount = json['new_orders_count'];
    acceptedOrdersCount = json['accepted_orders_count'];
    readyOrdersCount = json['ready_orders_count'];
    onAWayOrdersCount = json['on_a_way_orders_count'];
    ordersCount = json['orders_count'];
    totalPrice = json['last_delivered_fee'];
  }

  num? progressOrdersCount;
  num? deliveredOrdersCount;
  num? cancelOrdersCount;
  num? newOrdersCount;
  num? acceptedOrdersCount;
  num? readyOrdersCount;
  num? onAWayOrdersCount;
  num? ordersCount;
  dynamic totalPrice;

  CourierStatisticsData copyWith({
    num? progressOrdersCount,
    num? deliveredOrdersCount,
    num? cancelOrdersCount,
    num? newOrdersCount,
    num? acceptedOrdersCount,
    num? readyOrdersCount,
    num? onAWayOrdersCount,
    num? ordersCount,
    dynamic totalPrice,
  }) =>
      CourierStatisticsData(
        progressOrdersCount: progressOrdersCount ?? this.progressOrdersCount,
        deliveredOrdersCount: deliveredOrdersCount ?? this.deliveredOrdersCount,
        cancelOrdersCount: cancelOrdersCount ?? this.cancelOrdersCount,
        newOrdersCount: newOrdersCount ?? this.newOrdersCount,
        acceptedOrdersCount: acceptedOrdersCount ?? this.acceptedOrdersCount,
        readyOrdersCount: readyOrdersCount ?? this.readyOrdersCount,
        onAWayOrdersCount: onAWayOrdersCount ?? this.onAWayOrdersCount,
        ordersCount: ordersCount ?? this.ordersCount,
        totalPrice: totalPrice ?? this.totalPrice,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['progress_orders_count'] = progressOrdersCount;
    map['delivered_orders_count'] = deliveredOrdersCount;
    map['cancel_orders_count'] = cancelOrdersCount;
    map['new_orders_count'] = newOrdersCount;
    map['accepted_orders_count'] = acceptedOrdersCount;
    map['ready_orders_count'] = readyOrdersCount;
    map['on_a_way_orders_count'] = onAWayOrdersCount;
    map['orders_count'] = ordersCount;
    map['total_price'] = totalPrice;
    return map;
  }
}
