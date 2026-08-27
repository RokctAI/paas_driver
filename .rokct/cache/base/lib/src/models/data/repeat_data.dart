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


import 'dart:convert';

class RepeatData {
  String? id;
  String? orderId;
  String? from;
  String? to;
  String? createdAt;
  String? updatedAt;
  int? isActive;
  String? paymentMethod;
  String? savedCard;

  RepeatData({
    this.id,
    this.orderId,
    this.from,
    this.to,
    this.createdAt,
    this.updatedAt,
    this.isActive,
    this.paymentMethod,
    this.savedCard,
  });

  RepeatData copyWith({
    String? id,
    String? orderId,
    String? from,
    String? to,
    String? createdAt,
    String? updatedAt,
    int? isActive,
    String? paymentMethod,
    String? savedCard,
  }) =>
      RepeatData(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        from: from ?? this.from,
        to: to ?? this.to,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isActive: isActive ?? this.isActive,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        savedCard: savedCard ?? this.savedCard,
      );

  factory RepeatData.fromRawJson(String str) =>
      RepeatData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory RepeatData.fromJson(Map<String, dynamic> json) => RepeatData(
        id: json["id"]?.toString(),
        orderId: json["order_id"]?.toString(),
        from: json["from"],
        to: json["to"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
        isActive: json["is_active"],
        paymentMethod: json["payment_method"],
        savedCard: json["saved_card"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "order_id": orderId,
        "from": from,
        "to": to,
        "created_at": createdAt,
        "updated_at": updatedAt,
        "is_active": isActive,
        "payment_method": paymentMethod,
        "saved_card": savedCard,
      };
}
