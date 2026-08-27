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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:base_sdk/src/application/splash/splash_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class SplashNotifier extends StateNotifier<SplashState> {
  final SettingsRepositoryFacade _settingsRepository;

  SplashNotifier(this._settingsRepository) : super(const SplashState());

  Future<void> getToken(
    BuildContext context, {
    VoidCallback? goMain,
    VoidCallback? goLogin,
    VoidCallback? goNoInternet,
  }) async {
    // This will automatically show dialog if no connection
    final connect = await AppConnectivity.connectivityWithDialog(context);

    if (connect) {
      if (LocalStorage.getSettingsFetched()) {
        final response = await _settingsRepository.getGlobalSettings();
        response.when(
          success: (data) {
            LocalStorage.setSettingsList(data.data ?? []);
            LocalStorage.setSettingsFetched(true);
          },
          failure: (failure, status) {
            debugPrint('==> error with settings fetched');
            // No need for manual dialog call - handled by connectivity check
          },
        );
      }

      if (LocalStorage.getToken().isEmpty) {
        goLogin?.call();
      } else {
        goMain?.call();
      }

      if (!LocalStorage.getSettingsFetched()) {
        final response = await _settingsRepository.getGlobalSettings();
        response.when(
          success: (data) {
            LocalStorage.setSettingsList(data.data ?? []);
            LocalStorage.setSettingsFetched(true);
          },
          failure: (failure, status) {
            debugPrint('==> error with settings fetched');
            // No need for manual dialog call
          },
        );
      }
    }
    // No else block needed - dialog is automatically shown by connectivityWithDialog
  }

  Future<void> getTranslations(BuildContext context) async {
    // This will automatically show dialog if no connection
    final connect = await AppConnectivity.connectivityWithDialog(context);

    if (connect) {
      final response = await _settingsRepository.getMobileTranslations();
      response.when(
        success: (data) {
          LocalStorage.setTranslations(data.data);
        },
        failure: (failure, status) {
          debugPrint('==> error with fetching translations $failure');
          // Could show dialog here for API failures even with connection
          // AppHelpers.showNoConnectionDialog(context);
        },
      );
    }
    // No else block needed - dialog is automatically shown by connectivityWithDialog
  }
}
