import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/delete/delete_extras_group_state.dart';

/// Port of `paas_manager`'s `DeleteExtrasGroupNotifier`. Failures surface as
/// `state.error` (stage 2 convention).
class DeleteExtrasGroupNotifier extends StateNotifier<DeleteExtrasGroupState> {
  DeleteExtrasGroupNotifier(this._repository)
      : super(const DeleteExtrasGroupState());

  final SellerProductsRepositoryFacade _repository;

  Future<void> deleteExtrasGroup({
    VoidCallback? success,
    int? groupId,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.deleteExtrasGroup(groupId: groupId);
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        success?.call();
      },
      failure: (fail, status) {
        debugPrint('===> delete extras group fail $fail');
        state = state.copyWith(isLoading: false, error: fail);
      },
    );
  }
}
