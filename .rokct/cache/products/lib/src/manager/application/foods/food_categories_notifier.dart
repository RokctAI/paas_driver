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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';
import 'package:products_sdk/src/manager/application/foods/food_categories_state.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// Port of `paas_manager`'s `FoodCategoriesNotifier`.
///
/// `fetchCategories` no longer takes a `BuildContext` to raise a snackbar on
/// failure — the notifier reports through `state.error` and the page decides.
/// Same change as kitchen_sdk's picker, and for the same reason: presentation
/// concerns do not belong in the application layer, and the app's own notifiers
/// were inconsistent about it.
class FoodCategoriesNotifier extends StateNotifier<FoodCategoriesState> {
  FoodCategoriesNotifier(this._repository) : super(const FoodCategoriesState());

  final SellerCatalogRepositoryFacade _repository;

  int _page = 0;
  bool _hasMore = true;

  Future<void> initialFetchCategories() async {
    _page = 0;
    _hasMore = true;
    state = state.copyWith(activeIndex: 1, categories: [], isLoading: true);
    final response = await _repository.getCategories(page: ++_page);
    response.when(
      success: (data) {
        final List<SellerCategoryData> categories = data.data ?? [];
        _hasMore = categories.length >= 10;
        state = state.copyWith(categories: categories, isLoading: false);
      },
      failure: (failure, status) {
        debugPrint('====> initial fetch categories fail $failure');
        _page--;
        state = state.copyWith(isLoading: false, error: failure);
      },
    );
  }

  void setActiveIndex(int index) {
    if (state.activeIndex == index) return;
    state = state.copyWith(activeIndex: index);
  }

  Future<void> fetchCategories({
    RefreshController? refreshController,
    bool openingPage = false,
  }) async {
    if (openingPage) {
      if (state.activeIndex != 1) {
        state = state.copyWith(activeIndex: 1);
      }
      if (state.categories.isNotEmpty) return;
    }
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    if (_page == 0) {
      state = state.copyWith(isLoading: true);
    }
    final response = await _repository.getCategories(page: ++_page);
    response.when(
      success: (data) {
        final List<SellerCategoryData> categories = List.from(state.categories);
        final List<SellerCategoryData> newCategories = data.data ?? [];
        categories.addAll(newCategories);
        _hasMore = newCategories.length >= 10;
        if (_page == 1) {
          state = state.copyWith(isLoading: false, categories: categories);
        } else {
          state = state.copyWith(categories: categories);
        }
        refreshController?.loadComplete();
      },
      failure: (failure, status) {
        debugPrint('====> fetch categories fail $failure');
        _page--;
        if (_page == 0) {
          state = state.copyWith(isLoading: false);
        }
        state = state.copyWith(error: failure);
        refreshController?.loadFailed();
      },
    );
  }
}
