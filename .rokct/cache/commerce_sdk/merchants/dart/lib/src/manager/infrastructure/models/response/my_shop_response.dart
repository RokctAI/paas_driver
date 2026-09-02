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

/// Wrapper around base_sdk's [ShopData] for `seller_shop.get_shop` /
/// `update_shop`.
///
/// Tolerant of both envelopes: the legacy dashboard returned
/// `{data: {...}}`, while today's Frappe `get_shop` (after base_sdk's
/// `message` unwrap) returns the shop dict itself, flat — with `title` /
/// `description` / `address` as plain strings instead of a `translation`
/// object. The flat branch synthesizes the translation so every page keeps
/// reading `shop.translation?.title`.
///
/// `order_payment` is carried here rather than on [ShopData] (base's model
/// has no such field, and this is the only consumer); the current Frappe
/// `get_shop` does not return it yet — recorded in
/// `docs/frappe-endpoint-contract.md` — so it stays null until that lands
/// and the UI defaults to 'before'.
class MyShopResponse {
  MyShopResponse({this.data, this.orderPayment});

  ShopData? data;
  String? orderPayment;

  factory MyShopResponse.fromJson(dynamic json) {
    if (json == null) return MyShopResponse();
    final dynamic inner = json is Map && json['data'] != null
        ? json['data']
        : json;
    if (inner is! Map) return MyShopResponse();
    final Map<String, dynamic> shopJson = Map<String, dynamic>.from(inner);
    if (shopJson['translation'] == null &&
        (shopJson['title'] != null ||
            shopJson['description'] != null ||
            shopJson['address'] != null)) {
      shopJson['translation'] = {
        'title': shopJson['title']?.toString(),
        'description': shopJson['description']?.toString(),
        'address': shopJson['address']?.toString(),
      };
    }
    return MyShopResponse(
      data: ShopData.fromJson(shopJson),
      orderPayment: shopJson['order_payment']?.toString(),
    );
  }
}
