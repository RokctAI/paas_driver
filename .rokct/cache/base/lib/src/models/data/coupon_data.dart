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


class CouponData {
  CouponData({
    int? id,
    String? name,
    String? type,
    int? qty,
    num? price,
    String? expiredAt,
    String? createdAt,
    String? updatedAt,
  }) {
    _id = id;
    _name = name;
    _type = type;
    _qty = qty;
    _price = price;
    _expiredAt = expiredAt;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
  }

  CouponData.fromJson(dynamic json) {
    _id = json['id'];
    _name = json['name'];
    _type = json['type'];
    _qty = json['qty'];
    _price = json['price'];
    _expiredAt = json['expired_at'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }

  int? _id;
  String? _name;
  String? _type;
  int? _qty;
  num? _price;
  String? _expiredAt;
  String? _createdAt;
  String? _updatedAt;

  CouponData copyWith({
    int? id,
    String? name,
    String? type,
    int? qty,
    num? price,
    String? expiredAt,
    String? createdAt,
    String? updatedAt,
  }) =>
      CouponData(
        id: id ?? _id,
        name: name ?? _name,
        type: type ?? _type,
        qty: qty ?? _qty,
        price: price ?? _price,
        expiredAt: expiredAt ?? _expiredAt,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
      );

  int? get id => _id;

  String? get name => _name;

  String? get type => _type;

  int? get qty => _qty;

  num? get price => _price;

  String? get expiredAt => _expiredAt;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    map['type'] = _type;
    map['qty'] = _qty;
    map['price'] = _price;
    map['expired_at'] = _expiredAt;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    return map;
  }
}
