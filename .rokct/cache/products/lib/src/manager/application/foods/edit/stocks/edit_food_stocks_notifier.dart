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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/manager/application/foods/edit/stocks/edit_food_stocks_state.dart';
import 'package:products_sdk/src/manager/application/seller_product_requests.dart';

/// Port of `paas_manager`'s `EditFoodStocksNotifier` — the stock-variant
/// editor on the edit-product flow. Same mechanics as the create-flow variant
/// plus: seeded from the product's existing stocks, and deleted stocks are
/// tracked and sent as `delete_ids` on save.
///
/// Departures per stage 2 conventions: no `BuildContext`/snackbars (failures
/// surface as `state.error`), and the stock maps are built here
/// (`buildStocksRequest`) because the facade takes ready maps.
class EditFoodStocksNotifier extends StateNotifier<EditFoodStocksState> {
  EditFoodStocksNotifier(this._repository)
      : super(const EditFoodStocksState());

  final SellerProductsRepositoryFacade _repository;

  List<SellerStock> _localStocks = [];
  List<SellerStock> _oldStocks = [];

  void setStockAddons(List<SellerProductData> addons, int stockIndex) {
    final List<SellerAddonData> checkedAddons = [
      for (final addon in addons)
        if (addon.isSelectedAddon ?? false)
          SellerAddonData(addonId: addon.id, product: addon),
    ];
    _localStocks[stockIndex] =
        _localStocks[stockIndex].copyWith(localAddons: checkedAddons);
    state = state.copyWith(stocks: _localStocks);
  }

  void toggleCheckedGroup(int groupIndex) {
    final List<SellerExtrasGroup> groups = List.from(state.groups);
    final bool check =
        state.selectGroups.containsKey(groups[groupIndex].id.toString());
    groups[groupIndex] = groups[groupIndex].copyWith(isChecked: check);
    state = state.copyWith(groups: groups);
  }

  List<SellerExtrasGroup> _checkGroupsChecked(
    List<SellerExtrasGroup> groups,
    SellerProductData product,
  ) {
    for (int i = 0; i < groups.length; i++) {
      groups[i] = groups[i].copyWith(isChecked: false);
    }
    final List<SellerStock> stocks = product.stocks ?? [];
    if (stocks.isNotEmpty) {
      final List<SellerExtras> stockExtras = stocks.first.extras ?? [];
      for (int i = 0; i < groups.length; i++) {
        for (final extras in stockExtras) {
          if (extras.extraGroupId == groups[i].id) {
            groups[i] = groups[i].copyWith(isChecked: true);
          }
        }
      }
    }
    return groups;
  }

  Future<void> fetchGroups({required SellerProductData product}) async {
    if (state.groups.isNotEmpty) {
      List<SellerExtrasGroup> groups = List.from(state.groups);
      groups = _checkGroupsChecked(groups, product);
      state = state.copyWith(groups: groups);
      return;
    }
    state = state.copyWith(isFetchingGroups: true);
    final response = await _repository.getExtrasGroups();
    response.when(
      success: (data) {
        final List<SellerExtrasGroup> groups = data.data ?? [];
        state = state.copyWith(
          groups: _checkGroupsChecked(groups, product),
          isFetchingGroups: false,
        );
      },
      failure: (fail, status) {
        state = state.copyWith(isFetchingGroups: false);
      },
    );
  }

  Future<void> setActiveExtrasIndex({
    required int itemIndex,
    required int groupIndex,
  }) async {
    final String key = state.groups[groupIndex].id.toString();
    final SellerExtras extras =
        state.groups[groupIndex].fetchedExtras![itemIndex];
    final Map<String, List<SellerExtras?>> selectGroups =
        Map.from(state.selectGroups);
    if (selectGroups.containsKey(key)) {
      final List<SellerExtras?> list = selectGroups[key] ?? [];
      if (list.any((element) => element?.id == extras.id)) {
        list.removeWhere((element) => element?.id == extras.id);
        list.isEmpty ? selectGroups.remove(key) : selectGroups[key] = list;
      } else {
        list.add(state.groups[groupIndex].fetchedExtras![itemIndex]);
        selectGroups[key] = list;
      }
    } else {
      selectGroups[key] = [state.groups[groupIndex].fetchedExtras![itemIndex]];
    }
    state = state.copyWith(selectGroups: selectGroups);
    toggleCheckedGroup(groupIndex);
    combination();
    state = state.copyWith(stocks: _localStocks);
  }

  void combination() {
    List<SellerStock> stocks = [];
    if (state.selectGroups.values.isNotEmpty) {
      final List<List<SellerExtras>> list =
          cartesianExtras(List.from(state.selectGroups.values));
      stocks = List.generate(
        list.length,
        (index) => SellerStock(extras: list[index]),
      );
    } else {
      stocks = [SellerStock()];
    }
    for (int i = 0; i < _oldStocks.length; i++) {
      if (i < stocks.length) {
        stocks[i] = stocks[i].copyWith(
          price: _oldStocks[i].price,
          quantity: _oldStocks[i].quantity,
          sku: _oldStocks[i].sku,
        );
      }
    }
    _localStocks = stocks;
  }

  Future<void> fetchGroupExtras({
    required int groupIndex,
    VoidCallback? onSuccess,
  }) async {
    if (state.groups[groupIndex].fetchedExtras?.isNotEmpty ?? false) {
      state = state.copyWith(
        activeGroupExtras: state.groups[groupIndex].fetchedExtras ?? [],
      );
      return;
    }
    // Group ids are Product Extra Group docnames (hash strings).
    final String? groupId = state.groups[groupIndex].id;
    if (groupId == null) {
      debugPrint('===> fetch group extras skipped: group has no id');
      return;
    }
    state = state.copyWith(isLoading: true);
    final response = await _repository.getExtras(
      groupId: groupId,
    );
    response.when(
      success: (data) {
        final List<SellerExtras> fetchedExtras =
            data.data?.extraValues ?? <SellerExtras>[];
        final List<SellerExtrasGroup> activeGroups = List.from(state.groups);
        activeGroups[groupIndex] =
            activeGroups[groupIndex].copyWith(fetchedExtras: fetchedExtras);

        // Save the fetched extras back onto the matching group.
        final List<SellerExtrasGroup> groups = List.from(state.groups);
        int mainGroupIndex = 0;
        for (int i = 0; i < groups.length; i++) {
          if (groups[i].id == activeGroups[groupIndex].id) {
            mainGroupIndex = i;
          }
        }
        groups[mainGroupIndex] =
            groups[mainGroupIndex].copyWith(fetchedExtras: fetchedExtras);
        state = state.copyWith(
          isLoading: false,
          activeGroupExtras: fetchedExtras,
          groups: groups,
          stocks: _localStocks,
        );
      },
      failure: (fail, status) {
        state = state.copyWith(isLoading: false, error: fail);
        debugPrint('===> group extras fetching failed $fail');
      },
    );
  }

  void deleteStock(int index) {
    // Stock ids are Frappe docnames (hash strings). A stock without one
    // never existed server-side, so there is nothing to delete remotely.
    final String? stockId = _localStocks[index].id;
    final List<String> list = List.from(state.deleteStocks);
    if (stockId != null && stockId != '-1') list.add(stockId);
    _localStocks.removeAt(index);
    state = state.copyWith(stocks: _localStocks, deleteStocks: list);
  }

  void setQuantity({required String value, required int index}) {
    _localStocks[index] =
        _localStocks[index].copyWith(quantity: int.tryParse(value.trim()));
  }

  void setPrice({required String value, required int index}) {
    _localStocks[index] =
        _localStocks[index].copyWith(price: num.tryParse(value.trim()));
  }

  void setSku({required String value, required int index}) {
    _localStocks[index] = _localStocks[index].copyWith(sku: value.trim());
  }

  Future<void> updateStocks({
    String? uuid,
    VoidCallback? updated,
    VoidCallback? failed,
  }) async {
    state = state.copyWith(isSaving: true);
    final response = await _repository.updateStocks(
      uuid: uuid ?? '',
      stocks: buildStocksRequest(_localStocks),
      deletedStockIds: state.deleteStocks,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isSaving: false);
        updated?.call();
      },
      failure: (fail, status) {
        state = state.copyWith(isSaving: false, error: fail);
        failed?.call();
      },
    );
  }

  void addEmptyStock() {
    List<SellerExtras>? extras = _localStocks.last.extras;
    extras = extras?.map((e) => e.copyWith(value: null)).toList();
    _localStocks
        .add(_localStocks.last.copyWith(isInitial: true, extras: extras));
    state = state.copyWith(stocks: _localStocks);
  }

  void setInitialStocks(SellerProductData? product) {
    final List<SellerStock> stocks = product?.stocks ?? [];
    if (stocks.isEmpty) {
      stocks.add(SellerStock());
    }
    final Map<String, List<SellerExtras?>> selectGroups = {};
    for (final element in stocks) {
      element.extras?.forEach((extras) {
        final String key = extras.group?.id.toString() ?? '0';
        if (selectGroups.containsKey(key)) {
          final List<SellerExtras?> list = selectGroups[key] ?? [];
          list.add(extras);
        } else {
          selectGroups[key] = [extras];
        }
      });
    }
    state = state.copyWith(stocks: stocks, selectGroups: selectGroups);
    _localStocks = stocks;
    _oldStocks = stocks;
    fetchGroups(product: product ?? SellerProductData());
  }
}
