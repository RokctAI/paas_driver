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
import 'package:products_sdk/src/manager/application/extras/details/extras_group_details_state.dart';

/// Port of `paas_manager`'s `ExtrasGroupDetailsNotifier` — the values of one
/// extras group.
class ExtrasGroupDetailsNotifier
    extends StateNotifier<ExtrasGroupDetailsState> {
  ExtrasGroupDetailsNotifier(this._repository)
      : super(const ExtrasGroupDetailsState());

  final SellerProductsRepositoryFacade _repository;

  Future<void> fetchGroupExtras({String? groupId}) async {
    // Group ids are Product Extra Group docnames (hash strings).
    if (groupId == null) {
      debugPrint('===> fetch group extras skipped: no group id');
      return;
    }
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
