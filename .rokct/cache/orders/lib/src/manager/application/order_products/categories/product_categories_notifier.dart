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
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'product_categories_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class ProductCategoriesNotifier extends StateNotifier<ProductCategoriesState> {
  final PosProductsRepositoryFacade _catalogRepository;
  int _page = 0;
  bool _hasMore = true;

  ProductCategoriesNotifier(this._catalogRepository)
      : super(const ProductCategoriesState());

  Future<void> initialFetchCategories() async {
    if (state.categories.isNotEmpty) {
      if (state.activeIndex != 1) {
        state = state.copyWith(activeIndex: 1);
      }
      return;
    }
    state = state.copyWith(isLoading: true);
    final response = await _catalogRepository.getShopCategories(page: ++_page);
    response.when(
      success: (data) {
        final List<CategoryData> categories = data.data ?? [];
        _hasMore = categories.length >= 10;
        state = state.copyWith(categories: categories, isLoading: false);
      },
      failure: (fail,status) {
        debugPrint('===> initial fetch categories fail $fail');
        state = state.copyWith(isLoading: false);
        _page = 0;
      },
    );
  }

  void setActiveIndex(int index) {
    if (state.activeIndex == index) {
      return;
    }
    state = state.copyWith(activeIndex: index);
  }

  Future<void> fetchMoreCategories({
    RefreshController? refreshController,
    bool openingPage = false,
  }) async {
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    final response = await _catalogRepository.getShopCategories(page: ++_page);
    response.when(
      success: (data) {
        List<CategoryData> categories = List.from(state.categories);
        final List<CategoryData> newCategories = data.data ?? [];
        categories.addAll(newCategories);
        _hasMore = newCategories.length >= 10;
        state = state.copyWith(categories: categories);
        refreshController?.loadComplete();
      },
      failure: (failure,status) {
        debugPrint('====> fetch more categories fail $failure');
        _page--;
        refreshController?.loadFailed();
      },
    );
  }
}
