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

import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/working_days/working_days_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';

/// Port of paas_manager `application/restaurant/working_days/
/// working_days_notifier.dart`; the repository is this SDK's
/// [SellerShopRepositoryFacade] instead of the legacy `UsersInterface`, and
/// the day model is base_sdk's [ShopWorkingDay].
class WorkingDaysNotifier extends StateNotifier<WorkingDaysState> {
  final SellerShopRepositoryFacade _shopRepository;

  WorkingDaysNotifier(this._shopRepository) : super(const WorkingDaysState());

  Future<void> updateWorkingDays({
    required List<ShopWorkingDay> days,
    String? shopUuid,
    VoidCallback? updateSuccess,
  }) async {
    state = state.copyWith(isLoading: true, workingDays: days);
    final response = await _shopRepository.updateShopWorkingDays(
      workingDays: days,
      uuid: shopUuid,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        updateSuccess?.call();
      },
      failure: (failure, status) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> error update working days $failure');
      },
    );
  }

  void setShopWorkingDays(List<ShopWorkingDay> workingDays) {
    state = state.copyWith(workingDays: workingDays);
  }

  void changeIndex(ShopWorkingDay? day) {
    int index = 0;
    if (day != null) {
      for (int i = 0; i < state.workingDays.length; i++) {
        if (state.workingDays[i].id == day.id) {
          index = i;
        }
      }
    }
    state = state.copyWith(currentIndex: index);
  }
}
