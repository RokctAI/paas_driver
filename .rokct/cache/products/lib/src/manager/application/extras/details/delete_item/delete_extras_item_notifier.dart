import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/details/delete_item/delete_extras_item_state.dart';

/// Port of `paas_manager`'s `DeleteExtrasItemNotifier` — deletes one value of
/// an extras group. The facade's `deleteExtrasItem` takes the id list the
/// endpoint accepts; the app always sent exactly one.
class DeleteExtrasItemNotifier extends StateNotifier<DeleteExtrasItemState> {
  DeleteExtrasItemNotifier(this._repository)
      : super(const DeleteExtrasItemState());

  final SellerProductsRepositoryFacade _repository;

  Future<void> deleteExtrasItem({VoidCallback? success, int? extrasId}) async {
    state = state.copyWith(isLoading: true);
    final response =
        await _repository.deleteExtrasItem(ids: [extrasId ?? 0]);
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        success?.call();
      },
      failure: (fail, status) {
        debugPrint('===> delete extras item fail $fail');
        state = state.copyWith(isLoading: false, error: fail);
      },
    );
  }
}
