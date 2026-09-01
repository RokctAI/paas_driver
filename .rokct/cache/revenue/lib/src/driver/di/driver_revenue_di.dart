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

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_wallet.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/courier_statistics_repository.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/demo_courier_statistics_repository.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/driver_payout_repository.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/driver_wallet_repository.dart';

/// Driver-role DI hook. Not exported by the barrel — the common
/// `RevenueSdkDependencies.register` cannot import this file because a
/// manager app's cache has `lib/src/driver/` stripped. The manifest's
/// app_type.driver `di_hooks` entry injects the call into the generated
/// main.dart via this direct `src/` path (driver migration M4; a host mid
/// migration may still call it from its own DI setup too). Registers
/// idempotently so both call sites can coexist.
class DriverRevenueDependencies {
  static void register(GetIt getIt) {
    // Demo mode (--dart-define=IS_DEMO=true) swaps the HTTP facade for its
    // Demo* twin serving fictional earnings offline — the same isDemo split
    // delivery_sdk's DriverDeliveryDependencies applies to every courier
    // facade. Zero behavior change when IS_DEMO is off.
    if (!getIt.isRegistered<CourierStatisticsRepositoryFacade>()) {
      getIt.registerSingleton<CourierStatisticsRepositoryFacade>(
        AppConstants.isDemo
            ? DemoCourierStatisticsRepository()
            : CourierStatisticsRepository(),
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
  }
}
