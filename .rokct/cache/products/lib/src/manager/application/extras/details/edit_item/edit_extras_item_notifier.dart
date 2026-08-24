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
    String? groupId,
    String? extrasId,
  }) async {
    // Extras/group ids are Frappe docnames (hash strings); abort instead of
    // sending a sentinel the backend would no-op on.
    if (extrasId == null || groupId == null) {
      debugPrint('===> update extras item skipped: missing extras/group id');
      return;
    }
    state = state.copyWith(isLoading: true);
    final response = await _repository.updateExtrasItem(
      extrasId: extrasId,
      item: {'value': _title, 'extra_group_id': groupId},
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
