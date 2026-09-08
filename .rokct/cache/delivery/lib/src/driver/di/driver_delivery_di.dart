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

import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/services/demo_session.dart';

import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/domain/interface/deposit.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_parcel_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_route_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_deposit_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/deposit_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/parcel_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/route_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

/// Driver-role DI hook (revenue_sdk `DriverRevenueDependencies` precedent).
///
/// Not exported by the barrel and not called by the generated `main.dart` —
/// the common `DeliverySdkDependencies.register` cannot import this file
/// because a non-driver app's cache has `lib/src/driver/` stripped. A driver
/// host calls this from its own DI setup (e.g. paas_driver's
/// `setUpDependencies()`), importing it via this direct `src/` path.
/// Registers idempotently so hand-wired hosts can call it too.
///
/// Demo mode swaps every courier facade for its Demo* twin serving
/// DemoDeliverySeed data offline — the same split auth_sdk's
/// MockAuthRepository and lms_sdk's DemoLmsRepository use. Since the demo
/// login's phase 2 the switch is [DemoSession.demoActive]: the compile-time
/// `--dart-define=IS_DEMO=true` build OR the runtime demo session a
/// server-marked account opens after a real sign-in. It is read at
/// registration time and again on every flip: the hook keeps ONE listener
/// on [DemoSession.instance] (added once, rebound only when a different
/// container registers) that drops the facades this hook itself registered
/// and registers the other twin — after the login flow activates the
/// session and before the app routes on, and again when a sign-out clears
/// it. A host's own pre-registered implementation is never touched by the
/// swap (idempotent guards in [_Slot]), and nothing here throws at boot.
class DriverDeliveryDependencies {
  /// The five courier facades this hook owns, each with its Demo* twin.
  /// Design strip frames 49g/49h/49i own the last one: the driver's
  /// bank-deposit route on wallet's api.wallet.* defs.
  static final List<_Slot<Object>> _slots = <_Slot<Object>>[
    _Slot<CourierOrdersRepositoryFacade>(
      (demo) =>
          demo ? DemoCourierOrdersRepository() : CourierOrdersRepository(),
    ),
    _Slot<CourierParcelRepositoryFacade>(
      (demo) =>
          demo ? DemoCourierParcelRepository() : CourierParcelRepository(),
    ),
    _Slot<CourierRepositoryFacade>(
      (demo) => demo ? DemoCourierRepository() : CourierRepository(),
    ),
    _Slot<CourierRouteRepositoryFacade>(
      (demo) => demo ? DemoCourierRouteRepository() : CourierRouteRepository(),
    ),
    _Slot<DriverDepositRepositoryFacade>(
      (demo) => demo ? DemoDriverDepositRepository() : DriverDepositRepository(),
    ),
  ];

  /// The container the demo listener re-registers into, and the listener
  /// itself, so a second register() never adds a duplicate.
  static GetIt? _listened;
  static VoidCallback? _listener;

  static void register(GetIt getIt) {
    if (!getIt.isRegistered<HttpService>()) {
      getIt.registerSingleton<HttpService>(HttpService());
    }
    // Bind the listener first: binding to a NEW container forgets what
    // the hook owned in the previous one, and the ownership recorded by
    // the registration below is what the flip is allowed to drop.
    _listen(getIt);
    _registerFacades(getIt);
    // Pre-warm the synchronous CourierStorage.getOnline() read; fire and
    // forget is safe (see CourierStorage docs).
    CourierStorage.init();
  }

  /// Registers whichever twin [DemoSession.demoActive] asks for right now,
  /// skipping any facade already registered (a host's own, or this hook's
  /// from an earlier call).
  static void _registerFacades(GetIt getIt) {
    final bool demo = DemoSession.demoActive;
    for (final slot in _slots) {
      slot.register(getIt, demo);
    }
  }

  /// One listener per hook. Same container again: nothing to do. A
  /// different container (a test's `GetIt.asNewInstance()`): rebind.
  static void _listen(GetIt getIt) {
    if (identical(_listened, getIt)) return;
    detachDemoListener();
    void onDemoFlip() => _swap(getIt);
    DemoSession.instance.addListener(onDemoFlip);
    _listened = getIt;
    _listener = onDemoFlip;
  }

  /// The flip: drop the facades this hook registered (isRegistered-checked)
  /// and register the twin the session now asks for. Facades a host
  /// registered itself are left exactly as they were.
  static void _swap(GetIt getIt) {
    for (final slot in _slots) {
      slot.drop(getIt);
    }
    _registerFacades(getIt);
  }

  /// Removes the demo listener and forgets which facades this hook
  /// registered. Tests call it between containers; production never needs
  /// to, the listener lives as long as the app.
  @visibleForTesting
  static void detachDemoListener() {
    final VoidCallback? listener = _listener;
    if (listener != null) {
      DemoSession.instance.removeListener(listener);
    }
    _listener = null;
    _listened = null;
    for (final slot in _slots) {
      slot.forget();
    }
  }
}

/// One facade registration this hook may own: registers the twin [build]
/// picks for the current demo answer, remembers whether it was this hook
/// that registered it, and drops only its own registration on a flip.
class _Slot<T extends Object> {
  _Slot(this.build);

  final T Function(bool demo) build;

  bool _owned = false;

  void register(GetIt getIt, bool demo) {
    if (getIt.isRegistered<T>()) return;
    getIt.registerSingleton<T>(build(demo));
    _owned = true;
  }

  void drop(GetIt getIt) {
    if (!_owned) return;
    _owned = false;
    if (getIt.isRegistered<T>()) {
      getIt.unregister<T>();
    }
  }

  void forget() => _owned = false;
}

final GetIt _getIt = GetIt.instance;

/// Resolved lazily so import order never races registration. The getter
/// names mirror paas_driver's legacy `dependency_manager.dart` globals, so
/// the ported application/ slices read exactly as they did in the host.
HttpService get dioHttp => _getIt.get<HttpService>();

CourierOrdersRepositoryFacade get orderRepository =>
    _getIt.get<CourierOrdersRepositoryFacade>();

CourierParcelRepositoryFacade get parcelRepository =>
    _getIt.get<CourierParcelRepositoryFacade>();

CourierRepositoryFacade get courierRepository =>
    _getIt.get<CourierRepositoryFacade>();

CourierRouteRepositoryFacade get routeRepository =>
    _getIt.get<CourierRouteRepositoryFacade>();

DriverDepositRepositoryFacade get depositRepository =>
    _getIt.get<DriverDepositRepositoryFacade>();

/// Registered by map_sdk's `MapSdkDependencies.register` (map_sdk is part of
/// every driver compose — driver.json).
DrawRepositoryFacade get drawRepository => _getIt.get<DrawRepositoryFacade>();

/// Registered by products_sdk's `ProductsSdkDependencies.register`.
GalleryRepositoryFacade get galleryRepository =>
    _getIt.get<GalleryRepositoryFacade>();

/// Registered by users_sdk's `UsersSdkDependencies.register`.
UserRepositoryFacade get userRepository => _getIt.get<UserRepositoryFacade>();
