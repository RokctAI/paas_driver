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
