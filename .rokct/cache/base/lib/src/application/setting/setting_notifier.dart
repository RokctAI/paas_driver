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


import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:base_sdk/src/models/data/notification_list_data.dart';
import 'package:base_sdk/src/application/setting/setting_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class SettingNotifier extends StateNotifier<SettingState> {
  final SettingsRepositoryFacade _settingsRepository;
  final UserRepositoryFacade _userRepository;

  SettingNotifier(this._settingsRepository, this._userRepository)
      : super(const SettingState());

  void changeIndex(bool isChange) {
    state = state.copyWith(isLoading: isChange);
  }

  getNotificationList(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true);
      final response = await _settingsRepository.getNotificationList();

      response.when(
        success: (data) async {
          state = state.copyWith(notifications: data.data);
          final res = await _userRepository.getProfileDetails();
          res.when(
            success: (d) {
              for (int i = 0; i < data.data!.length; i++) {
                d.data?.notifications?.forEach((element) {
                  // Notification settings are keyed by their `type` (the
                  // settings endpoint emits no usable id).
                  if (data.data?[i].type != null &&
                      data.data?[i].type == element.type) {
                    updateData(context, i, element.active ?? false);
                  }
                });
              }

              state = state.copyWith(isLoading: false);
            },
            failure: (failure, status) {
              state = state.copyWith(isLoading: false);
              AppHelpers.showCheckTopSnackBar(context, failure);
            },
          );
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  updateData(BuildContext context, int index, bool active) async {
    List<NotificationData> list = List.from(state.notifications ?? []);
    NotificationData newNotification = list[index];
    newNotification.active = active;
    list.removeAt(index);
    list.insert(index, newNotification);
    state = state.copyWith(notifications: list);
    _settingsRepository.updateNotification(state.notifications);
  }
}
