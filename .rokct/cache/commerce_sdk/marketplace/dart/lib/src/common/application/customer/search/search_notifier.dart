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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/products.dart';
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:marketplace_sdk/src/common/application/customer/search/search_state.dart';

class SearchNotifier extends StateNotifier<SearchState> {
  final ShopsRepositoryFacade _shopsRepository;
  final ProductsRepositoryFacade _productsRepository;

  SearchNotifier(this._shopsRepository, this._productsRepository)
      : super(const SearchState());
  int productIndex = 1;

  init() {
    List<String> list = LocalStorage.getSearchList();
    state = state.copyWith(searchHistory: list, search: "");
  }

  void setSelectCategory(
    int index,
    BuildContext context, {
    String? categoryId,
  }) {
    if (state.selectIndexCategory == index) {
      state = state.copyWith(selectIndexCategory: -1);
    } else {
      state = state.copyWith(selectIndexCategory: index);
    }
    if (state.search.isNotEmpty) {
      searchProduct(context, state.search);
      searchShop(context, state.search, categoryId: categoryId);
    }
  }

  void changeSearch(String text) async {
    List<String> list = List.from(state.searchHistory);
    if (text.isNotEmpty && !list.contains(text)) {
      list.add(text);
    }
    state = state.copyWith(search: text, searchHistory: list);
    LocalStorage.setSearchHistory(list);
  }

  void clearAllHistory() {
    state = state.copyWith(searchHistory: []);
    LocalStorage.deleteSearchList();
  }

  void clearHistory(int index) {
    List<String> list = List.from(state.searchHistory);
    list.removeAt(index);
    state = state.copyWith(searchHistory: list);
    LocalStorage.setSearchHistory(list);
  }

  Future<void> searchShop(
    BuildContext context,
    String text, {
    String? categoryId,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isShopLoading: true);
      final response = await _shopsRepository.searchShops(
        text: text,
        categoryId: categoryId,
      );
      response.when(
        success: (data) async {
          state = state.copyWith(isShopLoading: false, shops: data.data ?? []);
        },
        failure: (failure, status) {
          state = state.copyWith(isShopLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> searchProduct(BuildContext context, String text) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isProductLoading: true);
      final response = await _productsRepository.searchProducts(text: text);
      response.when(
        success: (data) async {
          state = state.copyWith(
            isProductLoading: false,
            products: data.data ?? [],
          );
        },
        failure: (failure, status) {
          state = state.copyWith(isProductLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> searchProductPage(BuildContext context, String text) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      final response = await _productsRepository.searchProducts(
        text: text,
        page: ++productIndex,
      );
      response.when(
        success: (data) async {
          if (data.data != null) {
            List<ProductData> list = List.from(state.products);
            list.addAll(data.data!);
            state = state.copyWith(products: list);
          } else {
            productIndex--;
          }
        },
        failure: (failure, status) {
          productIndex--;
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }
}
