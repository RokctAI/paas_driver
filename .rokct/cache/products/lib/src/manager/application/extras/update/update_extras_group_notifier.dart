import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/update/update_extras_group_state.dart';

/// Port of `paas_manager`'s `UpdateExtrasGroupNotifier`. Same body-building
/// and locale notes as `CreateExtrasGroupNotifier`.
class UpdateExtrasGroupNotifier extends StateNotifier<UpdateExtrasGroupState> {
  UpdateExtrasGroupNotifier(this._repository)
      : super(const UpdateExtrasGroupState());

  final SellerProductsRepositoryFacade _repository;

  String _title = '';

  Future<void> updateExtrasGroup({
    VoidCallback? success,
    int? groupId,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.updateExtrasGroup(
      groupId: groupId ?? 0,
      group: {
        'title': {LocalStorage.getLanguage()?.locale ?? 'en': _title},
        'type': 'text',
      },
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        success?.call();
      },
      failure: (fail, status) {
        debugPrint('===> update extras group fail $fail');
        state = state.copyWith(isLoading: false, error: fail);
      },
    );
  }

  void setTitle(String value) {
    _title = value.trim();
  }
}
