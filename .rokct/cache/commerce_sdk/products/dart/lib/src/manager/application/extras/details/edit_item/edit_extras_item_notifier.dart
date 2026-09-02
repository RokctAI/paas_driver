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
