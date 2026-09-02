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


import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/currencies.dart';
import 'package:base_sdk/src/domain/interface/notification.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/settings_repository.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/mock_settings_repository.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/currencies_repository.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/notification_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `CommsSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class CommsSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<SettingsRepositoryFacade>()) {
      getIt.registerSingleton<SettingsRepositoryFacade>(
        AppConstants.isDemo ? MockSettingsRepository() : SettingsRepository(),
      );
    }
    if (!getIt.isRegistered<CurrenciesRepositoryFacade>()) {
      getIt.registerSingleton<CurrenciesRepositoryFacade>(CurrenciesRepository());
    }
    if (!getIt.isRegistered<NotificationRepositoryFacade>()) {
      getIt.registerSingleton<NotificationRepositoryFacade>(NotificationRepositoryImpl());
    }
  }
}
