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


import 'package:base_sdk/src/models/data/cart_product_data.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';

class ShopTotalData {
  final ShopData shopData;
  final double shopTax;
  final double onlyShopTax;
  final double discount;
  final double totalPrice;
  final List<CartProductData> cartProducts;

  ShopTotalData(
    this.shopData, {
    required this.shopTax,
    required this.onlyShopTax,
    required this.discount,
    required this.totalPrice,
    required this.cartProducts,
  });
}
