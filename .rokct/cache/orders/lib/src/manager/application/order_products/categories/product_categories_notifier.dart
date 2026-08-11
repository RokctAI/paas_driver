import 'package:flutter/material.dart';
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
