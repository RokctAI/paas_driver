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
