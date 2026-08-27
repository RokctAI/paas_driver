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


import 'package:base_sdk/src/models/data/product_data.dart';

class BonusModel {
  BonusModel({
    this.bonusableType,
    this.bonusableId,
    this.bonusQuantity,
    this.bonusStockId,
    this.value,
    this.type,
    this.status,
    this.expiredAt,
    this.bonusStock,
  });

  String? bonusableType;
  num? bonusableId;
  num? bonusQuantity;
  num? bonusStockId;
  num? value;
  String? type;
  bool? status;
  DateTime? expiredAt;
  BonusStock? bonusStock;

  factory BonusModel.fromJson(Map<String, dynamic>? json) {
    return BonusModel(
      bonusableType: json?["bonusable_type"],
      bonusableId: json?["bonusable_id"],
      bonusQuantity: json?["bonus_quantity"],
      bonusStockId: json?["bonus_stock_id"],
      value: json?["value"],
      type: json?["type"],
      expiredAt: DateTime.tryParse(json?["expired_at"] ?? '')?.toLocal(),
      bonusStock: json?["bonusStock"] != null
          ? BonusStock.fromJson(json?["bonusStock"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "bonusable_type": bonusableType,
        "bonusable_id": bonusableId,
        "bonus_quantity": bonusQuantity,
        "bonus_stock_id": bonusStockId,
        "value": value,
        "type": type,
        "status": status,
        "expired_at":
            "${expiredAt?.year.toString().padLeft(4, '0')}-${expiredAt?.month.toString().padLeft(2, '0')}-${expiredAt?.day.toString().padLeft(2, '0')}",
        "bonusStock": bonusStock?.toJson(),
      };
}

class BonusStock {
  BonusStock({
    this.id,
    this.countableId,
    this.price,
    this.quantity,
    this.tax,
    this.totalPrice,
    this.product,
  });

  num? id;
  num? countableId;
  num? price;
  num? quantity;
  num? tax;
  num? totalPrice;
  ProductData? product;

  factory BonusStock.fromJson(Map<String, dynamic> json) => BonusStock(
        id: json["id"],
        countableId: json["countable_id"],
        price: json["price"],
        quantity: json["quantity"],
        tax: json["tax"],
        totalPrice: json["total_price"],
        product: json["product"] != null
            ? ProductData.fromJson(json["product"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "countable_id": countableId,
        "price": price,
        "quantity": quantity,
        "tax": tax,
        "total_price": totalPrice,
      };
}
