import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/manager/application/addons/addons_state.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// Port of `paas_manager`'s `AddonsNotifier` — the seller's addon list
/// (the "addons" tab of the foods screen), with search debounce and cursor
/// pagination.
class AddonsNotifier extends StateNotifier<AddonsState> {
  AddonsNotifier(this._repository) : super(const AddonsState());

  final SellerProductsRepositoryFacade _repository;

  int _page = 0;
  bool _hasMore = true;
  Timer? _timer;
  String _query = '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _search() async {
    _hasMore = true;
    _page = 0;
    state = state.copyWith(isLoading: true);
    final response = await _repository.getProducts(
      page: ++_page,
      query: _query.isEmpty ? null : _query.trim(),
      needAddons: true,
    );
    response.when(
      success: (data) {
        final List<SellerProductData> addons = data.data ?? [];
        _hasMore = addons.length >= 10;
        state = state.copyWith(addons: addons, isLoading: false);
      },
      failure: (fail, status) {
        debugPrint('===> search addon fail $fail');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> fetchMoreAddons({RefreshController? refreshController}) async {
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    final response = await _repository.getProducts(
      page: ++_page,
      query: _query.isEmpty ? null : _query.trim(),
      needAddons: true,
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

  Future<void> initialFetchAddons() async {
    if (state.addons.isNotEmpty) {
      return;
    }
    _page = 0;
    _hasMore = true;
    _query = '';
    state = state.copyWith(isLoading: true);
    final response =
        await _repository.getProducts(page: ++_page, needAddons: true);
    response.when(
      success: (data) {
        final List<SellerProductData> addons = data.data ?? [];
        _hasMore = addons.length >= 10;
        state = state.copyWith(isLoading: false, addons: addons);
      },
      failure: (fail, status) {
        debugPrint('===> fetch addons fail $fail');
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> refreshAddons({RefreshController? refreshController}) async {
    refreshController?.resetNoData();
    _hasMore = true;
    _page = 0;
    final response = await _repository.getProducts(
      page: ++_page,
      query: _query.isEmpty ? null : _query.trim(),
      needAddons: true,
    );
    response.when(
      success: (data) {
        final List<SellerProductData> addons = data.data ?? [];
        state = state.copyWith(addons: addons);
        _hasMore = addons.length >= 10;
        refreshController?.refreshCompleted();
      },
      failure: (error, status) {
        debugPrint('===> refresh addons fail $error');
        refreshController?.refreshFailed();
      },
    );
  }

  void updateSingleAddon(SellerProductData? addon) {
    final List<SellerProductData> addons = List.from(state.addons);
    int? index;
    for (int i = 0; i < addons.length; i++) {
      if (addon?.id == addons[i].id) {
        index = i;
      }
    }
    if (index != null && addon != null) {
      addons[index] = addon;
      state = state.copyWith(addons: addons);
    }
  }

  void setQuery(String text) {
    if (_query == text) {
      return;
    }
    _query = text.trim();
    _timer?.cancel();
    // The app branched on empty-vs-non-empty and ran the identical body in
    // both arms; collapsed, same as stage 2's FoodsNotifier.setQuery.
    _timer = Timer(const Duration(milliseconds: 500), _search);
  }
}
