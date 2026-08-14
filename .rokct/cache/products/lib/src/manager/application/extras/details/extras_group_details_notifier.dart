import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/details/extras_group_details_state.dart';

/// Port of `paas_manager`'s `ExtrasGroupDetailsNotifier` — the values of one
/// extras group.
class ExtrasGroupDetailsNotifier
    extends StateNotifier<ExtrasGroupDetailsState> {
  ExtrasGroupDetailsNotifier(this._repository)
      : super(const ExtrasGroupDetailsState());

  final SellerProductsRepositoryFacade _repository;

  Future<void> fetchGroupExtras({int? groupId}) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.getExtras(groupId: groupId);
    response.when(
      success: (data) {
        state = state.copyWith(
          extras: data.data?.extraValues ?? [],
          isLoading: false,
        );
      },
      failure: (fail, status) {
        debugPrint('===> fetch extras fail $fail');
        state = state.copyWith(isLoading: false);
      },
    );
  }
}
