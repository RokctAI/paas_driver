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


import 'package:base_sdk/src/models/data/shop_data.dart';

class RefundOrdersModel {
  RefundOrdersModel({this.data});

  List<RefundModel>? data;

  factory RefundOrdersModel.fromJson(Map<String, dynamic> json) =>
      RefundOrdersModel(
        data: json["data"] == null
            ? []
            : List<RefundModel>.from(
                json["data"]!.map((x) => RefundModel.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class RefundModel {
  RefundModel({
    this.id,
    this.status,
    this.cause,
    this.answer,
    this.createdAt,
    this.updatedAt,
    this.order,
  });

  String? id;
  String? status;
  String? cause;
  String? answer;
  DateTime? createdAt;
  DateTime? updatedAt;
  Order? order;

  factory RefundModel.fromJson(Map<String, dynamic> json) => RefundModel(
        id: json["id"]?.toString(),
        status: json["status"],
        cause: json["cause"],
        answer: json["answer"],
        createdAt: DateTime.tryParse(json["created_at"])?.toLocal(),
        updatedAt: DateTime.tryParse(json["updated_at"])?.toLocal(),
        order: json["order"] != null ? Order.fromJson(json["order"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "status": status,
        "cause": cause,
        "answer": answer,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "order": order!.toJson(),
      };
}

class Order {
  Order({this.id, this.shop});

  String? id;
  ShopData? shop;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json["id"]?.toString(),
        shop: json["shop"] != null ? ShopData.fromJson(json["shop"]) : null,
      );

  Map<String, dynamic> toJson() => {"id": id};
}
