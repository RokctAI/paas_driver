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
