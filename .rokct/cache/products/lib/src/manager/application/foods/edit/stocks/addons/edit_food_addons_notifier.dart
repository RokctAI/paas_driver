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
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/manager/application/foods/edit/stocks/addons/edit_food_addons_state.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// Port of `paas_manager`'s `EditFoodAddonsNotifier` — the addon picker for a
/// stock variant on the edit-product flow. The app's version never raised
/// snackbars here, so this is a straight port.
class EditFoodAddonsNotifier extends StateNotifier<EditFoodAddonsState> {
  EditFoodAddonsNotifier(this._repository)
      : super(const EditFoodAddonsState());

  final SellerProductsRepositoryFacade _repository;

  int _page = 0;
  bool _hasMore = true;

  void toggleAddonSelection(int index) {
    final List<SellerProductData> addons = List.from(state.addons);
    addons[index] = addons[index]
        .copyWith(isSelectedAddon: !(addons[index].isSelectedAddon ?? false));
    state = state.copyWith(addons: addons);
  }

  Future<void> fetchMoreAddons({RefreshController? refreshController}) async {
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    final response = await _repository.getProducts(
      page: ++_page,
      needAddons: true,
      status: 'published',
    );
    response.when(
      success: (data) {
        final List<SellerProductData> addons = List.from(state.addons);
        final List<SellerProductData> newAddons = data.data ?? [];
        addons.addAll(newAddons);
        _hasMore = newAddons.length >= 10;
        refreshController?.loadComplete();
        state = state.copyWith(addons: addons);
      },
      failure: (fail, status) {
        debugPrint('===> fetch more addons fail $fail');
        refreshController?.loadFailed();
      },
    );
  }

  Future<void> initialFetchAddons(SellerStock stock) async {
    if (state.addons.isNotEmpty) {
      final List<SellerProductData> addons = List.from(state.addons);
      for (int i = 0; i < addons.length; i++) {
        addons[i] = addons[i].copyWith(isSelectedAddon: false);
      }
      final List<SellerAddonData> productAddons = stock.localAddons ?? [];
      for (final productAddon in productAddons) {
        for (int i = 0; i < addons.length; i++) {
          if (addons[i].id == productAddon.product?.id) {
            addons[i] = addons[i].copyWith(isSelectedAddon: true);
          }
        }
      }
      state = state.copyWith(addons: addons);
      return;
    }
    _page = 0;
    _hasMore = true;
    state = state.copyWith(isLoading: true);
    final response = await _repository.getProducts(
      page: ++_page,
      needAddons: true,
      status: 'published',
    );
    response.when(
      success: (data) {
        final List<SellerProductData> addons = data.data ?? [];
        _hasMore = addons.length >= 10;
        for (int i = 0; i < addons.length; i++) {
          addons[i] = addons[i].copyWith(isSelectedAddon: false);
        }
        final List<SellerAddonData> productAddons = stock.addons ?? [];
        for (final productAddon in productAddons) {
          for (int i = 0; i < addons.length; i++) {
            if (addons[i].id == productAddon.product?.id) {
              addons[i] = addons[i].copyWith(isSelectedAddon: true);
            }
          }
        }
        state = state.copyWith(isLoading: false, addons: addons);
      },
      failure: (fail, status) {
        debugPrint('===> fetch addons fail $fail');
        state = state.copyWith(isLoading: false, addons: []);
      },
    );
  }
}
