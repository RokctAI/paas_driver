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
    String? groupId,
  }) async {
    // Group ids are Product Extra Group docnames (hash strings); abort
    // instead of sending a sentinel the backend would no-op on.
    if (groupId == null) {
      debugPrint('===> update extras group skipped: no group id');
      return;
    }
    state = state.copyWith(isLoading: true);
    final response = await _repository.updateExtrasGroup(
      groupId: groupId,
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
