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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_cart_state.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class OrderCartNotifier extends StateNotifier<OrderCartState> {
  OrderCartNotifier() : super(const OrderCartState());

  void deleteStockFromCart({
    required Stock stock,
    Function(List<Stock>)? updateProducts,
  }) {
    List<Stock> stocks = List.from(state.stocks);
    num price = state.totalPrice;
    price -= stock.totalPrice ?? 0;
    final addons = stock.addons?.where((e) => e.active ?? false).toList() ?? [];
    for (var e in addons) {
      price -= e.product?.stock?.totalPrice ?? 0;
    }
    stocks.remove(stock);
    stocks = stocks.toSet().toList();
    state = state.copyWith(stocks: stocks, totalPrice: price);
    if (updateProducts != null) {
      updateProducts(stocks);
    }
  }

  void clearAll() {
    state = state.copyWith(stocks: []);
  }

  void addStockToCart({
    required int count,
    ProductData? product,
    Stock? stock,
    Function(List<Stock>)? updateProducts,
  }) {
    debugPrint('===> add stock to cart count $count');
    debugPrint('===> add stock to cart product ${product?.translation?.title}');
    List<Stock> stocks = List.from(state.stocks);
    int? index;
    for (int i = 0; i < stocks.length; i++) {
      if (stocks[i].id == stock?.id) {
        bool next = true;
        List<AddonData> lastAddons =
            stocks[i].addons?.where((e) => e.active ?? false).toList() ?? [];
        List<AddonData> newAddons =
            stock?.addons?.where((e) => e.active ?? false).toList() ?? [];
        for (var element in lastAddons) {
          if (!(newAddons.any((e) => e.id == element.id && e.quantity ==element.quantity) ) ) {
            next = false;
          }
        }
        if (lastAddons.isEmpty && newAddons.isEmpty) {
          index = i;
          break;
        } else if (lastAddons.length != newAddons.length) {
          index = null;
        } else if (next) {
          index = i;
          break;
        } else {
          index = null;
        }
      }
    }
    if (index != null) {
      if (count == 0) {
        stocks.removeAt(index);
      } else {
        stocks[index] = stocks[index].copyWith(cartCount: count);
      }
    } else {
      stock = stock?.copyWith(product: product, cartCount: count);
      if (stock != null) {
        stocks.insert(0, stock);
      }
    }
    stocks = stocks.toList();
    num sum = 0;
    for (final stock in stocks) {
      sum += (stock.totalPrice ?? 0) * (stock.cartCount ?? 0);
      for (AddonData addon in stock.addons ?? []) {
        if (addon.active ?? false) {
          sum +=
              (addon.product?.stock?.totalPrice ?? 0) * (addon.quantity ?? 1);
        }
      }
    }
    state = state.copyWith(stocks: stocks, totalPrice: sum);
    if (updateProducts != null) {
      updateProducts(stocks);
    }
  }
}
