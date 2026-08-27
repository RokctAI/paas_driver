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
