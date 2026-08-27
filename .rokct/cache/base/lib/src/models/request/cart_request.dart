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
