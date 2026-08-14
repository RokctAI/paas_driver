import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/details/edit_item/edit_extras_item_state.dart';

/// Port of `paas_manager`'s `EditExtrasItemNotifier` — renames a value of an
/// extras group. Same body-building and error-surfacing notes as
/// `CreateNewGroupItemNotifier`.
class EditExtrasItemNotifier extends StateNotifier<EditExtrasItemState> {
  EditExtrasItemNotifier(this._repository)
      : super(const EditExtrasItemState());

  final SellerProductsRepositoryFacade _repository;

  String _title = '';

  Future<void> updateExtrasItem({
    VoidCallback? success,
    int? groupId,
    int? extrasId,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.updateExtrasItem(
      extrasId: extrasId ?? 0,
      item: {'value': _title, 'extra_group_id': groupId ?? 0},
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        success?.call();
      },
      failure: (fail, status) {
        debugPrint('===> update extras item fail $fail');
        state = state.copyWith(isLoading: false, error: fail);
      },
    );
  }

  void setTitle(String value) {
    _title = value.trim();
  }
}
