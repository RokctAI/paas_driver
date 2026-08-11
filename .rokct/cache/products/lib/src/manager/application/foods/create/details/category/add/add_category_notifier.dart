import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/category/add/add_category_state.dart';

/// Port of `paas_manager`'s `AddCategoryNotifier` — the inline "new category"
/// form on the create-product flow. Failures surface as `state.error` instead
/// of an in-notifier snackbar (stage 2 convention).
///
/// The app parsed `input` to an int before sending; the facade's
/// `createCategory` takes it as the raw string and the repository forwards it,
/// so the trimmed text is passed straight through.
class AddCategoryNotifier extends StateNotifier<AddCategoryState> {
  AddCategoryNotifier(this._repository) : super(const AddCategoryState());

  final SellerCatalogRepositoryFacade _repository;

  String _title = '';
  String _input = '';

  Future<void> createCategory({VoidCallback? success}) async {
    state = state.copyWith(isLoading: true);
    final response =
        await _repository.createCategory(title: _title, input: _input);
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        success?.call();
      },
      failure: (fail, status) {
        debugPrint('===> create category fail $fail');
        state = state.copyWith(isLoading: false, error: fail);
      },
    );
  }

  void setTitle(String value) {
    _title = value.trim();
  }

  void setInput(String value) {
    _input = value.trim();
  }
}
