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
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/manager/application/foods/create/stocks/addons/create_food_addons_state.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// Port of `paas_manager`'s `CreateFoodAddonsNotifier` — the addon picker for
/// a stock variant on the create-product flow. Failures surface as
/// `state.error` instead of an in-notifier snackbar (stage 2 convention).
class CreateFoodAddonsNotifier extends StateNotifier<CreateFoodAddonsState> {
  CreateFoodAddonsNotifier(this._repository)
      : super(const CreateFoodAddonsState());

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
        state = state.copyWith(error: fail);
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
        state = state.copyWith(isLoading: false, addons: [], error: fail);
      },
    );
  }
}
