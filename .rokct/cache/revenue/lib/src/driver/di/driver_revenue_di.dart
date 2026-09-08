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

import 'package:base_sdk/src/services/demo_session.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_wallet.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/courier_statistics_repository.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/demo_courier_statistics_repository.dart';
import 'package:revenue_sdk/src/common/infrastructure/repositories/driver_payout_repository.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/driver_wallet_repository.dart';

/// Driver-role DI hook. Not exported by the barrel — the common
/// `RevenueSdkDependencies.register` cannot import this file because a
/// manager app's cache has `lib/src/driver/` stripped. The manifest's
/// app_type.driver `di_hooks` entry injects the call into the generated
/// main.dart via this direct `src/` path (driver migration M4; a host mid
/// migration may still call it from its own DI setup too). Registers
/// idempotently so both call sites can coexist.
///
/// The statistics facade has a Demo* twin serving fictional earnings
/// offline. Which of the two is registered follows base's
/// [DemoSession.demoActive]: a demo BUILD (`--dart-define=IS_DEMO=true`,
/// the tour and the store screenshots) or a demo SESSION (a server-marked
/// account signed in on the production backend). The build half is a
/// compile-time constant and answers at [register]; the session half flips
/// at runtime - after login, before routing, and back on sign-out - so the
/// hook also subscribes ONCE to [DemoSession.instance] and swaps the
/// registration in place on every flip. The providers that draw the income
/// page resolve the facade from GetIt when they are first built, which on
/// both paths is after the flip. Zero behavior change for a real account
/// in a production build.
class DriverRevenueDependencies {
  static VoidCallback? _demoSessionListener;

  static void register(GetIt getIt) {
    if (!getIt.isRegistered<CourierStatisticsRepositoryFacade>()) {
      getIt.registerSingleton<CourierStatisticsRepositoryFacade>(
        _courierStatistics(),
      );
    }
    if (!getIt.isRegistered<DriverPayoutRepositoryFacade>()) {
      getIt.registerSingleton<DriverPayoutRepositoryFacade>(
        DriverPayoutRepository(),
      );
    }
    if (!getIt.isRegistered<DriverWalletRepositoryFacade>()) {
      getIt.registerSingleton<DriverWalletRepositoryFacade>(
        DriverWalletRepository(),
      );
    }
    _listenToDemoSession(getIt);
  }

  /// The facade for the demo switch's CURRENT position. Read at every
  /// (re-)registration rather than captured, so a flip never serves a
  /// twin picked at boot.
  static CourierStatisticsRepositoryFacade _courierStatistics() =>
      DemoSession.demoActive
          ? DemoCourierStatisticsRepository()
          : CourierStatisticsRepository();

  /// One listener for the life of the process, whichever call site
  /// registered first; a host that also calls [register] by hand during
  /// its migration window does not subscribe twice.
  static void _listenToDemoSession(GetIt getIt) {
    if (_demoSessionListener != null) return;
    final listener = () => _swapDemoTwins(getIt);
    _demoSessionListener = listener;
    DemoSession.instance.addListener(listener);
  }

  /// Re-registers the facades that have a demo twin for the switch's new
  /// position. The other facades are the same class on both sides and stay
  /// as they are. Guarded so it cannot throw: unregister only what is
  /// registered, then register fresh.
  static void _swapDemoTwins(GetIt getIt) {
    if (getIt.isRegistered<CourierStatisticsRepositoryFacade>()) {
      getIt.unregister<CourierStatisticsRepositoryFacade>();
    }
    getIt.registerSingleton<CourierStatisticsRepositoryFacade>(
      _courierStatistics(),
    );
  }

  /// Drops the process-wide subscription so a test that resets GetIt
  /// between cases does not carry a listener bound to the previous case's
  /// registrations. The app never calls this.
  @visibleForTesting
  static void resetDemoSessionListener() {
    final listener = _demoSessionListener;
    if (listener == null) return;
    DemoSession.instance.removeListener(listener);
    _demoSessionListener = null;
  }
}
