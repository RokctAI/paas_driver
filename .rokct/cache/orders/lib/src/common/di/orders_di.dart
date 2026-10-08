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
import 'package:base_sdk/base_sdk.dart' show DemoFixtures;
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/domain/interface/parcel.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/orders_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/cart_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/parcel_repository.dart';
import 'package:orders_sdk/src/common/infrastructure/services/cart_sync_handler.dart';

/// Host asset directory holding orders_sdk's demo platform fixtures
/// (`<cmd>.json`), installed from `templates/assets/demo/orders`.
const String ordersDemoFixtureDirectory = 'assets/demo/orders';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `OrdersSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
///
/// Demo runs the REAL repositories: base_sdk's DemoGatewayInterceptor
/// answers every platform cmd they send from the `<cmd>.json` fixtures in
/// [ordersDemoFixtureDirectory] while DemoSession.demoActive (read per
/// request, so a demo account signing in later is honoured), and an
/// unknown cmd fails loudly with DemoFixtureMissing. The same directory
/// carries the manager's seeded shift for SellerOrdersRepository.
class OrdersSdkDependencies {
  static void register(GetIt getIt) {
    DemoFixtures.registerAssetDirectory(ordersDemoFixtureDirectory);
    if (!getIt.isRegistered<OrdersRepositoryFacade>()) {
      getIt.registerSingleton<OrdersRepositoryFacade>(OrdersRepository());
    }
    if (!getIt.isRegistered<CartRepositoryFacade>()) {
      getIt.registerSingleton<CartRepositoryFacade>(CartRepository());
    }
    if (!getIt.isRegistered<ParcelRepositoryFacade>()) {
      getIt.registerSingleton<ParcelRepositoryFacade>(ParcelRepository());
    }
    _attachCartSync(getIt);
  }

  /// Attach the cart.sync push handler so customer cart snapshots queued
  /// offline by base_sdk's ShopOrderNotifier drain to the server cart
  /// (ManagerOrdersDependencies' order.create pattern). It lives in this
  /// common hook — not the manager one — because the customer cart is a
  /// customer/marketplace flow and those composes never call manager DI
  /// (their caches have lib/src/manager/ stripped). Reuses the facade
  /// registered above.
  /// BaseSdkDependencies.register puts the engine in get_it before feature
  /// SDKs run; the process-singleton fallback keeps hand-wired hosts that
  /// skipped it working. registerHandler replaces any previous handler, so
  /// this is idempotent too. Requires base_sdk >= 1.6.0 (CustomerCartStore
  /// / kCartSyncOpType and SyncEngine.enqueueOrReplace).
  static void _attachCartSync(GetIt getIt) {
    final engine = getIt.isRegistered<SyncEngine>()
        ? getIt<SyncEngine>()
        : SyncEngine();
    engine.registerHandler(
      CartSyncHandler.opType,
      CartSyncHandler(getIt<CartRepositoryFacade>()),
    );
  }
}
