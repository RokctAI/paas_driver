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


import 'dart:convert';

GetCalculateModel getCalculateModelFromJson(String str) =>
    GetCalculateModel.fromJson(json.decode(str));

String getCalculateModelToJson(GetCalculateModel data) =>
    json.encode(data.toJson());

class GetCalculateModel {
  GetCalculateModel({
    this.totalTax,
    this.price,
    this.totalShopTax,
    this.totalPrice,
    this.totalDiscount,
    this.bonusShop,
    this.deliveryFee,
    this.serviceFee,
    this.couponPrice,
    this.containsAdultItems = false,
    this.requiresBirthDate = false,
  });

  num? totalTax;
  num? price;
  num? totalShopTax;
  num? totalPrice;
  num? totalDiscount;
  dynamic bonusShop;
  num? deliveryFee;
  num? serviceFee;
  num? couponPrice;

  /// Whether the order contains age-restricted (18+) items.
  bool containsAdultItems;

  /// Whether the backend requires the customer's birth date to proceed.
  bool requiresBirthDate;

  factory GetCalculateModel.fromJson(Map<String, dynamic> json) =>
      GetCalculateModel(
        totalTax: json["total_tax"],
        price: json["price"],
        totalShopTax: json["total_shop_tax"],
        totalPrice: json["total_price"],
        totalDiscount: json["total_discount"],
        bonusShop: json["bonus_shop"],
        deliveryFee: json["delivery_fee"],
        serviceFee: json["service_fee"],
        couponPrice: json["coupon_price"],
        containsAdultItems: json["contains_adult_items"] == true ||
            json["contains_adult_items"] == 1 ||
            json["contains_adult_items"] == '1',
        requiresBirthDate: json["requires_birth_date"] == true ||
            json["requires_birth_date"] == 1 ||
            json["requires_birth_date"] == '1',
      );

  Map<String, dynamic> toJson() => {
        "total_tax": totalTax,
        "price": price,
        "total_shop_tax": totalShopTax,
        "total_price": totalPrice,
        "total_discount": totalDiscount,
        "bonus_shop": bonusShop,
        "delivery_fee": deliveryFee,
        "rate": serviceFee,
        "coupon_price": couponPrice,
        "contains_adult_items": containsAdultItems,
        "requires_birth_date": requiresBirthDate,
      };
}
