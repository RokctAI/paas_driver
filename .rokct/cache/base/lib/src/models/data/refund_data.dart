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
