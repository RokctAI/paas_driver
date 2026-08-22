// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
