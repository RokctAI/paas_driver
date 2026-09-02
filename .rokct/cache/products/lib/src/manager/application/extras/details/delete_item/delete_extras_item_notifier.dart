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
