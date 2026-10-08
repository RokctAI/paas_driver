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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/common/translation_seeder.dart';

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
    bool backendUp = true,
  }) async {
    final connect = await AppConnectivity.connectivity();

    if (connect) {
      // The radio being up says nothing about the tenant backend: a Wi-Fi
      // network with no route to it false-passes connectivity(). When the
      // splash's api_status probe already answered "down", every
      // getGlobalSettings() below is a guaranteed dio timeout the person
      // waits through BEFORE any routing happens — the splash sat there for
      // the whole of it. Route on what is already stored and leave the
      // settings refresh to the next start that finds a backend.
      if (!backendUp) {
        if (LocalStorage.getToken().isEmpty) {
          goLogin?.call();
        } else {
          goMain?.call();
        }
        return;
      }

      if (LocalStorage.getSettingsFetched()) {
        final response = await _settingsRepository.getGlobalSettings();
        response.when(
          success: (data) {
            LocalStorage.setSettingsList(data.data ?? []);
            LocalStorage.setSettingsFetched(true);
          },
          failure: (failure, status) {
            debugPrint('==> error with settings fetched');
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
          },
        );
      }
    } else {
      goNoInternet?.call();
    }
  }

  Future<void> getTranslations(BuildContext context) async {
    final connect = await AppConnectivity.connectivity();

    if (connect) {
      final response = await _settingsRepository.getMobileTranslations();
      response.when(
        success: (data) {
          LocalStorage.setTranslations(data.data);
          // Fire-and-forget: offer the app's bundled translation keys to
          // the backend (insert-only server-side). Never blocks splash,
          // never surfaces errors.
          TranslationSeeder.pushMissingKeys();
        },
        failure: (failure, status) {
          debugPrint('==> error with fetching translations $failure');
        },
      );
    }
  }
}
