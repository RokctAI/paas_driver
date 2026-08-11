import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/extras_state.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// Port of `paas_manager`'s `ExtrasNotifier` — the extras-group management
/// list. `needOnlyValid: false` so groups without values still show up for
/// editing.
class ExtrasNotifier extends StateNotifier<ExtrasState> {
  ExtrasNotifier(this._repository) : super(const ExtrasState());

  final SellerProductsRepositoryFacade _repository;

  Future<void> fetchGroups({RefreshController? refreshController}) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.getExtrasGroups(needOnlyValid: false);
    response.when(
      success: (data) {
        state = state.copyWith(groups: data.data ?? [], isLoading: false);
        refreshController?.refreshCompleted();
      },
      failure: (fail, status) {
        debugPrint('===> fetch groups fail $fail');
        state = state.copyWith(isLoading: false);
        refreshController?.refreshFailed();
      },
    );
  }
}
