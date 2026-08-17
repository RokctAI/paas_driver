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
