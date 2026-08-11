import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/create/create_extras_group_state.dart';

/// Port of `paas_manager`'s `CreateExtrasGroupNotifier`. The group body the
/// app repository built moved here (facade takes a ready map); title keyed on
/// the display locale — the stage 2 `createCategory` departure, same reason.
/// Failures surface as `state.error` (stage 2 convention).
class CreateExtrasGroupNotifier extends StateNotifier<CreateExtrasGroupState> {
  CreateExtrasGroupNotifier(this._repository)
      : super(const CreateExtrasGroupState());

  final SellerProductsRepositoryFacade _repository;

  String _title = '';

  Future<void> createExtrasGroup({VoidCallback? success}) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.createExtrasGroup(
      group: {
        'title': {LocalStorage.getLanguage()?.locale ?? 'en': _title},
        'active': 1,
        'type': 'text',
      },
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        success?.call();
      },
      failure: (fail, status) {
        debugPrint('===> create extras group fail $fail');
        state = state.copyWith(isLoading: false, error: fail);
      },
    );
  }

  void setTitle(String value) {
    _title = value.trim();
  }
}
