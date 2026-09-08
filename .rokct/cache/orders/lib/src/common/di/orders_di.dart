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
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/domain/interface/parcel.dart';
import 'package:base_sdk/src/services/demo_session.dart';
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
///
/// The demo twins follow the RUNTIME demo switch, base_sdk's
/// [DemoSession.demoActive] (a demo build OR a demo session): the
/// facades are chosen by that read at registration, and the one listener
/// this hook adds to [DemoSession.instance] swaps them again when the
/// switch flips - after a demo account's login, before routing, and back
/// on sign-out. Only registrations this hook made are ever swapped; a
/// facade a host registered itself is left alone.
class OrdersSdkDependencies {
  /// The container the last [register] call wired; the listener re-wires
  /// the same one. Null until the first call, so a flip that lands before
  /// any registration is a no-op and the registration then reads the
  /// switch itself.
  static GetIt? _container;

  /// Guards the listener against being added twice: `register` is
  /// idempotent by contract and hand-wired hosts do call it again.
  static bool _listening = false;

  /// The instances this hook registered, so a flip replaces exactly those
  /// and never a host's own registration. Weak, so a container a test
  /// threw away is not kept alive by it.
  static final Expando<bool> _ours = Expando<bool>();

  static void register(GetIt getIt) {
    _container = getIt;
    _registerDemoTwins(getIt, replace: false);
    if (!getIt.isRegistered<ParcelRepositoryFacade>()) {
      getIt.registerSingleton<ParcelRepositoryFacade>(ParcelRepository());
    }
    _attachCartSync(getIt);
    if (!_listening) {
      _listening = true;
      DemoSession.instance.addListener(_onDemoSessionChanged);
    }
  }

  /// The facades that have a demo twin. `replace` is false at boot (an
  /// existing registration wins, as before) and true on a flip (this
  /// hook's own registration is dropped and rebuilt for the new side).
  /// Nothing here can throw: unregister runs only behind `isRegistered`,
  /// and a fresh registration never collides.
  static void _registerDemoTwins(GetIt getIt, {required bool replace}) {
    final bool demo = DemoSession.demoActive;
    _put<OrdersRepositoryFacade>(
      getIt,
      () => demo ? MockOrdersRepository() : OrdersRepository(),
      replace: replace,
    );
    _put<CartRepositoryFacade>(
      getIt,
      () => demo ? MockCartRepository() : CartRepository(),
      replace: replace,
    );
  }

  static void _put<T extends Object>(
    GetIt getIt,
    T Function() build, {
    required bool replace,
  }) {
    if (getIt.isRegistered<T>()) {
      if (!replace || _ours[getIt<T>()] != true) return;
      getIt.unregister<T>();
    }
    final T instance = build();
    _ours[instance] = true;
    getIt.registerSingleton<T>(instance);
  }

  static void _onDemoSessionChanged() {
    final GetIt? getIt = _container;
    if (getIt == null) return;
    _registerDemoTwins(getIt, replace: true);
    // The cart push handler captured the previous facade; re-attach it
    // over the one just registered (registerHandler replaces).
    _attachCartSync(getIt);
  }

  /// Attach the cart.sync push handler so customer cart snapshots queued
  /// offline by base_sdk's ShopOrderNotifier drain to the server cart
  /// (ManagerOrdersDependencies' order.create pattern). It lives in this
  /// common hook — not the manager one — because the customer cart is a
  /// customer/marketplace flow and those composes never call manager DI
  /// (their caches have lib/src/manager/ stripped). Reuses the facade
  /// registered above, so demo composes push against the mock.
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
