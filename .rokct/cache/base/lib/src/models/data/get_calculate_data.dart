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
