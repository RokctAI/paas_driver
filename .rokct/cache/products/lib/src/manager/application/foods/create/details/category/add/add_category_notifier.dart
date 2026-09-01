// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
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
