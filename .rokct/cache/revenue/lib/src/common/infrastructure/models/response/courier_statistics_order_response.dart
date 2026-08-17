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

// To parse this JSON data, do
//
//     final statisticsOrderModel = statisticsOrderModelFromJson(jsonString);

import 'dart:convert';

CourierStatisticsOrderResponse statisticsOrderModelFromJson(String str) =>
    CourierStatisticsOrderResponse.fromJson(json.decode(str));

String statisticsOrderModelToJson(CourierStatisticsOrderResponse data) =>
    json.encode(data.toJson());

class CourierStatisticsOrderResponse {
  CourierStatisticsOrderResponse({
    this.timestamp,
    this.status,
    this.message,
    this.data,
  });

  DateTime? timestamp;
  bool? status;
  String? message;
  List<CourierStatisticsOrder>? data;

  CourierStatisticsOrderResponse copyWith({
    DateTime? timestamp,
    bool? status,
    String? message,
    List<CourierStatisticsOrder>? data,
  }) =>
      CourierStatisticsOrderResponse(
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory CourierStatisticsOrderResponse.fromJson(Map<String, dynamic> json) =>
      CourierStatisticsOrderResponse(
        timestamp: json["timestamp"] == null
            ? null
            : DateTime.tryParse(json["timestamp"])?.toLocal(),
        status: json["status"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<CourierStatisticsOrder>.from(
                json["data"]!.map((x) => CourierStatisticsOrder.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp?.toIso8601String(),
        "status": status,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class CourierStatisticsOrder {
  CourierStatisticsOrder({
    this.createdAt,
    this.totalPrice,
    this.fmTotalPrice,
  });

  DateTime? createdAt;
  double? totalPrice;
  double? fmTotalPrice;

  CourierStatisticsOrder copyWith({
    DateTime? createdAt,
    double? totalPrice,
    double? fmTotalPrice,
  }) =>
      CourierStatisticsOrder(
        createdAt: createdAt ?? this.createdAt,
        totalPrice: totalPrice ?? this.totalPrice,
        fmTotalPrice: fmTotalPrice ?? this.fmTotalPrice,
      );

  factory CourierStatisticsOrder.fromJson(Map<String, dynamic> json) =>
      CourierStatisticsOrder(
        createdAt: json["created_at"] == null
            ? null
            : DateTime.tryParse(json["created_at"])?.toLocal(),
        totalPrice: json["total_price"]?.toDouble(),
        fmTotalPrice: json["fm_total_price"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "created_at": createdAt?.toIso8601String(),
        "total_price": totalPrice,
        "fm_total_price": fmTotalPrice,
      };
}
