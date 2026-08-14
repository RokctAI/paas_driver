import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/details/new_item/create_new_group_item_state.dart';

/// Port of `paas_manager`'s `CreateNewGroupItemNotifier` — adds a value to an
/// extras group. The item body the app repository built
/// (`{'value': ..., 'extra_group_id': ...}`) moved here; failures surface as
/// `state.error` (stage 2 conventions).
class CreateNewGroupItemNotifier
    extends StateNotifier<CreateNewGroupItemState> {
  CreateNewGroupItemNotifier(this._repository)
      : super(const CreateNewGroupItemState());

  final SellerProductsRepositoryFacade _repository;

  String _title = '';

  Future<void> createExtrasItem({VoidCallback? success, int? groupId}) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.createExtrasItem(
      item: {'value': _title, 'extra_group_id': groupId ?? 0},
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        success?.call();
      },
      failure: (fail, status) {
        debugPrint('===> create extras item fail $fail');
        state = state.copyWith(isLoading: false, error: fail);
      },
    );
  }

  void setTitle(String value) {
    _title = value.trim();
  }
}
