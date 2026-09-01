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


import 'package:base_sdk/src/services/local_storage.dart';

class CartRequest {
  final String? shopId;
  final String? cartId;
  final String? userUuid;
  final String? stockId;
  final String? productId;
  final String? parentId;
  final int? quantity;
  final List<CartRequest>? carts;

  CartRequest({
    this.shopId,
    this.stockId,
    this.productId,
    this.parentId,
    this.quantity,
    this.carts,
    this.cartId,
    this.userUuid,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (productId != null) map["product_id"] = productId;
    if (shopId != null) map["shop_id"] = shopId;
    if (cartId != null) map["cart_id"] = cartId;
    if (userUuid != null) map["user_cart_uuid"] = userUuid;
    if (stockId != null) map["stock_id"] = stockId;
    if (parentId != null) map["parent_id"] = parentId;
    if (quantity != null) map["quantity"] = quantity;
    map["rate"] = LocalStorage.getSelectedCurrency()?.rate ?? 1;
    final currencyId = LocalStorage.getSelectedCurrency()?.id;
    if (currencyId != null) map["currency_id"] = currencyId;
    return map;
  }

  Map<String, dynamic> toJsonInsert() {
    final map = <String, dynamic>{};
    if (shopId != null) map["shop_id"] = shopId;
    map["lang"] = LocalStorage.getLanguage()?.locale;
    map["rate"] = LocalStorage.getSelectedCurrency()?.rate ?? 1;
    final currencyId = LocalStorage.getSelectedCurrency()?.id;
    if (currencyId != null) map["currency_id"] = currencyId;
    if (cartId != null) map["cart_id"] = cartId;
    if (userUuid != null) map["user_cart_uuid"] = userUuid;
    if (carts != null) map["products"] = toJsonCart();
    return map;
  }

  List<Map<String, dynamic>> toJsonCart() {
    List<Map<String, dynamic>> list = [];
    carts?.forEach((element) {
      final map = <String, dynamic>{};
      map["stock_id"] = element.stockId;
      map["quantity"] = element.quantity;
      if (element.parentId != null) map["parent_id"] = element.parentId;
      if (cartId != null) map["cart_id"] = cartId;
      if (userUuid != null) map["user_cart_uuid"] = userUuid;
      if (!(element.quantity == 0 && element.parentId != null)) {
        list.add(map);
      }
    });

    return list;
  }
}
