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


import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/models/data/cart_product_data.dart';

part 'shop_order_state.freezed.dart';

@freezed
abstract class ShopOrderState with _$ShopOrderState {
  const factory ShopOrderState({
    @Default(false) bool isLoading,
    @Default(false) bool isStartGroupLoading,
    @Default(false) bool isStartGroup,
    @Default(false) bool isOtherShop,
    @Default(false) bool isDeleteLoading,
    @Default(false) bool isCheckShopOrder,
    @Default(false) bool isAddAndRemoveLoading,
    @Default(false) bool isEditOrder,
    @Default("") String shareLink,
    @Default(null) Cart? cart,
    @Default([]) List<CartProductData> productList,
  }) = _ShopOrderState;

  const ShopOrderState._();
}
