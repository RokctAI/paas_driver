// Copyright (c) 2026 RokctAI
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

import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/domain/interface/parcel.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/orders_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/mock_orders_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/cart_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/mock_cart_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/parcel_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/services/cart_sync_handler.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `OrdersSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class OrdersSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<OrdersRepositoryFacade>()) {
      getIt.registerSingleton<OrdersRepositoryFacade>(
        AppConstants.isDemo ? MockOrdersRepository() : OrdersRepository(),
      );
    }
    if (!getIt.isRegistered<CartRepositoryFacade>()) {
      getIt.registerSingleton<CartRepositoryFacade>(
        AppConstants.isDemo ? MockCartRepository() : CartRepository(),
      );
    }
    if (!getIt.isRegistered<ParcelRepositoryFacade>()) {
      getIt.registerSingleton<ParcelRepositoryFacade>(ParcelRepository());
    }
    // Attach the cart.sync push handler so customer cart snapshots queued
    // offline by base_sdk's ShopOrderNotifier drain to the server cart
    // (ManagerOrdersDependencies' order.create pattern). It lives in this
    // common hook — not the manager one — because the customer cart is a
    // customer/marketplace flow and those composes never call manager DI
    // (their caches have lib/src/manager/ stripped). Reuses the facade
    // registered above, so demo composes push against the mock.
    // BaseSdkDependencies.register puts the engine in get_it before feature
    // SDKs run; the process-singleton fallback keeps hand-wired hosts that
    // skipped it working. registerHandler replaces any previous handler, so
    // this is idempotent too. Requires base_sdk >= 1.6.0 (CustomerCartStore
    // / kCartSyncOpType and SyncEngine.enqueueOrReplace).
    final engine =
        getIt.isRegistered<SyncEngine>() ? getIt<SyncEngine>() : SyncEngine();
    engine.registerHandler(
      CartSyncHandler.opType,
      CartSyncHandler(getIt<CartRepositoryFacade>()),
    );
  }
}
