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


import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/domain/interface/currencies.dart';
import 'package:base_sdk/src/domain/interface/notification.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/settings_repository.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/mock_settings_repository.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/currencies_repository.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/notification_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `CommsSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
///
/// The settings repository has a demo twin, and which one is registered
/// follows [DemoSession.demoActive] - a demo BUILD or a demo SESSION - not
/// the compile-time constant alone: read at registration, and re-read on
/// every flip of [DemoSession.instance] (a demo account signing in after
/// boot, a sign-out ending its session), when the singleton is replaced.
/// Only a registration this hook made is ever replaced; a host that wired
/// its own facade first keeps it across flips.
class CommsSdkDependencies {
  /// One listener per container, however often [register] is called.
  static final Map<GetIt, VoidCallback> _sessionListeners = {};

  static void register(GetIt getIt) {
    if (!getIt.isRegistered<SettingsRepositoryFacade>()) {
      getIt.registerSingleton<SettingsRepositoryFacade>(_settingsRepository());
      _followDemoSession(getIt);
    }
    if (!getIt.isRegistered<CurrenciesRepositoryFacade>()) {
      getIt.registerSingleton<CurrenciesRepositoryFacade>(CurrenciesRepository());
    }
    if (!getIt.isRegistered<NotificationRepositoryFacade>()) {
      getIt.registerSingleton<NotificationRepositoryFacade>(NotificationRepositoryImpl());
    }
  }

  static SettingsRepositoryFacade _settingsRepository() =>
      DemoSession.demoActive ? MockSettingsRepository() : SettingsRepository();

  static void _followDemoSession(GetIt getIt) {
    if (_sessionListeners.containsKey(getIt)) return;
    void swap() {
      if (getIt.isRegistered<SettingsRepositoryFacade>()) {
        getIt.unregister<SettingsRepositoryFacade>();
      }
      getIt.registerSingleton<SettingsRepositoryFacade>(_settingsRepository());
    }

    _sessionListeners[getIt] = swap;
    DemoSession.instance.addListener(swap);
  }

  /// Detaches the flip listener [register] attached for [getIt], so one
  /// test's container never leaks a swap into the next. Test-only.
  @visibleForTesting
  static void stopFollowingDemoSession(GetIt getIt) {
    final listener = _sessionListeners.remove(getIt);
    if (listener != null) DemoSession.instance.removeListener(listener);
  }
}
