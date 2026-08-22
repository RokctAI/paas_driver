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

import 'dart:async';
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_products_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class OrderProductsNotifier extends StateNotifier<OrderProductsState> {
  final PosProductsRepositoryFacade _productsRepository;
  int _page = 0;
  bool _hasMore = true;
  Timer? _timer;
  String _query = '';

  OrderProductsNotifier(this._productsRepository)
      : super(const OrderProductsState());

  void updateProducts({required List<Stock> cartStocks}) {
    List<ProductData> products = List.from(state.products);
    for (int i = 0; i < products.length; i++) {
      products[i] = products[i].copyWith(cartCount: 0);
      int count = 0;
      int? index;
      for (final stock in cartStocks) {
        if (stock.product?.id == products[i].id) {
          count += stock.cartCount ?? 0;
          index = i;
        }
      }
      if (index != null) {
        products[index] = products[index].copyWith(cartCount: count);
      }
    }
    state = state.copyWith(products: products);
  }

  void setQuery({
    required String query,
    required List<Stock> cartStocks,
    int? categoryId,
  }) {
    if (_query == query) {
      return;
    }
    _query = query.trim();
    if (_query.isNotEmpty) {
      if (_timer?.isActive ?? false) {
        _timer?.cancel();
      }
      _timer = Timer(
        const Duration(milliseconds: 500),
        () {
          fetchProducts(
            isRefresh: true,
            categoryId: categoryId,
            cartStocks: cartStocks,
          );
        },
      );
    } else {
      if (_timer?.isActive ?? false) {
        _timer?.cancel();
      }
      _timer = Timer(
        const Duration(milliseconds: 500),
        () {
          fetchProducts(
            isRefresh: true,
            categoryId: categoryId,
            cartStocks: cartStocks,
          );
        },
      );
    }
  }

  Future<void> fetchProducts({
    RefreshController? refreshController,
    bool isRefresh = false,
    bool isOpeningPage = false,
    int? categoryId,
    required List<Stock> cartStocks,
  }) async {
    if (isRefresh) {
      _page = 0;
      _hasMore = true;
      refreshController?.requestRefresh();
    } else {
      if (state.products.isNotEmpty && isOpeningPage) {
        List<ProductData> products = List.from(state.products);
        for (int i = 0; i < products.length; i++) {
          products[i] = products[i].copyWith(cartCount: 0);
          for (final stock in cartStocks) {
            if (stock.product?.id == products[i].id) {
              final int count = products[i].cartCount ?? 0;
              products[i] = products[i].copyWith(
                cartCount: count + (stock.cartCount ?? 0),
              );
            }
          }
        }
        state = state.copyWith(products: products);
        return;
      }
    }
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    if (_page == 0 && !isRefresh) {
      state = state.copyWith(isLoading: true);
    }
    final response = await _productsRepository.getProducts(
      active: true,
      page: ++_page,
      categoryId: categoryId,
      query: _query.isEmpty ? null : _query,
      // Legacy ProductStatus enum collapsed to its wire string (products_sdk
      // made the same cut in its facade).
      status: 'published',
    );
    response.when(
      success: (data) {
        List<ProductData> products = isRefresh ? [] : List.from(state.products);
        final List<ProductData> newProducts = data.data ?? [];
        products.addAll(newProducts);
        for (int i = 0; i < products.length; i++) {
          for (final stock in cartStocks) {
            if (stock.product?.id == products[i].id) {
              final int count = products[i].cartCount ?? 0;
              products[i] = products[i].copyWith(
                cartCount: count + (stock.cartCount ?? 0),
              );
            }
          }
        }
        _hasMore = newProducts.length >= 10;
        if (_page == 1 && !isRefresh) {
          state = state.copyWith(isLoading: false, products: products);
        } else {
          state = state.copyWith(products: products);
        }
        if (isRefresh) {
          refreshController?.refreshCompleted();
        } else {
          refreshController?.loadComplete();
        }
      },
      failure: (failure,status) {
        debugPrint('====> fetch products fail $failure');
        _page--;
        if (_page == 0) {
          state = state.copyWith(isLoading: false);
        }
        if (isRefresh) {
          refreshController?.refreshFailed();
        } else {
          refreshController?.loadFailed();
        }
      },
    );
  }
}
