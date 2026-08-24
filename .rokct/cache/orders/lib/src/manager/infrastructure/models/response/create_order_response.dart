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

class CreateOrderResponse {
  CreateOrderResponse({CreatedOrder? data, this.localId}) {
    _data = data;
  }

  CreateOrderResponse.fromJson(dynamic json) : localId = null {
    _data = json['data'] != null ? CreatedOrder.fromJson(json['data']) : null;
  }

  CreatedOrder? _data;

  /// Set instead of [data] when the order was queued locally (backend
  /// unreachable): the `offline:<uuid>` key of the manager_orders record.
  /// The POS keys on it until the sync handler swaps in the backend id.
  final String? localId;

  CreateOrderResponse copyWith({CreatedOrder? data}) =>
      CreateOrderResponse(data: data ?? _data, localId: localId);

  CreatedOrder? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}

class CreatedOrder {
  CreatedOrder({
    String? id,
    String? userId,
    num? price,
    num? currencyPrice,
    num? rate,
  }) {
    _id = id;
    _userId = userId;
    _price = price;
    _currencyPrice = currencyPrice;
    _rate = rate;
  }

  CreatedOrder.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _userId = json['user_id']?.toString();
    _price = json['price'];
    _currencyPrice = json['currency_price'];
    _rate = json['rate'];
  }

  String? _id;
  String? _userId;
  num? _price;
  num? _currencyPrice;
  num? _rate;

  CreatedOrder copyWith({
    String? id,
    String? userId,
    num? price,
    num? currencyPrice,
    num? rate,
  }) =>
      CreatedOrder(
        id: id ?? _id,
        userId: userId ?? _userId,
        price: price ?? _price,
        currencyPrice: currencyPrice ?? _currencyPrice,
        rate: rate ?? _rate,
      );

  String? get id => _id;

  String? get userId => _userId;

  num? get price => _price;

  num? get currencyPrice => _currencyPrice;

  num? get rate => _rate;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user_id'] = _userId;
    map['price'] = _price;
    map['currency_price'] = _currencyPrice;
    map['rate'] = _rate;
    return map;
  }
}
