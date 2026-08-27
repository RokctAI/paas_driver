// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
import 'package:products_sdk/src/manager/application/extras/details/delete_item/delete_extras_item_state.dart';

/// Port of `paas_manager`'s `DeleteExtrasItemNotifier` — deletes one value of
/// an extras group. The facade's `deleteExtrasItem` takes the id list the
/// endpoint accepts; the app always sent exactly one.
class DeleteExtrasItemNotifier extends StateNotifier<DeleteExtrasItemState> {
  DeleteExtrasItemNotifier(this._repository)
      : super(const DeleteExtrasItemState());

  final SellerProductsRepositoryFacade _repository;

  Future<void> deleteExtrasItem({
    VoidCallback? success,
    String? extrasId,
  }) async {
    // Extra value ids are Frappe docnames (hash strings).
    if (extrasId == null) {
      debugPrint('===> delete extras item skipped: no extras id');
      return;
    }
    state = state.copyWith(isLoading: true);
    final response = await _repository.deleteExtrasItem(ids: [extrasId]);
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
