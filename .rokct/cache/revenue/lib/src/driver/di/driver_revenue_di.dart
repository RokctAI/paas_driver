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
