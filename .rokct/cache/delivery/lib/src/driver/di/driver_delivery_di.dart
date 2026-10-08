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

import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/handlers/demo_gateway_interceptor.dart';

import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/domain/interface/deposit.dart';
import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:delivery_sdk/src/driver/domain/interface/poi.dart';
import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/deposit_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/load_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/parcel_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/poi_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/route_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

/// Host asset directory holding delivery_sdk's demo platform fixtures
/// (`<cmd>.json`), installed from `templates/assets/demo/delivery`.
const String deliveryDemoFixtureDirectory = 'assets/demo/delivery';

/// Driver-role DI hook (revenue_sdk `DriverRevenueDependencies` precedent).
///
/// Not exported by the barrel and not called by the generated `main.dart` —
/// the common `DeliverySdkDependencies.register` cannot import this file
/// because a non-driver app's cache has `lib/src/driver/` stripped. A driver
/// host calls this from its own DI setup (e.g. paas_driver's
/// `setUpDependencies()`), importing it via this direct `src/` path.
/// Registers idempotently so hand-wired hosts can call it too.
///
/// Demo runs the REAL courier repositories (Ray, 2026-09-25): base_sdk's
/// DemoGatewayInterceptor answers every platform cmd they send from the
/// `<cmd>.json` fixtures in [deliveryDemoFixtureDirectory] while
/// `DemoSession.demoActive`, read per request, so a session that flips
/// after login needs no re-registration and a wrong cmd fails loudly
/// (DemoFixtureMissing). A host's own pre-registered implementation is
/// never touched (isRegistered guards), and nothing here throws at boot.
class DriverDeliveryDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<HttpService>()) {
      getIt.registerSingleton<HttpService>(HttpService());
    }
    DemoFixtures.registerAssetDirectory(deliveryDemoFixtureDirectory);
    // Design strip frames 49g/49h/49i own the deposit facade (wallet's
    // api.wallet.* defs); van sales ride commerce's api.order.load.* defs;
    // points of interest ride map's api.poi.* defs.
    _put<CourierOrdersRepositoryFacade>(getIt, CourierOrdersRepository.new);
    _put<CourierParcelRepositoryFacade>(getIt, CourierParcelRepository.new);
    _put<CourierRepositoryFacade>(getIt, CourierRepository.new);
    _put<CourierRouteRepositoryFacade>(getIt, CourierRouteRepository.new);
    _put<DriverDepositRepositoryFacade>(getIt, DriverDepositRepository.new);
    _put<DriverLoadRepositoryFacade>(getIt, DriverLoadRepository.new);
    _put<DriverPoiRepositoryFacade>(getIt, DriverPoiRepository.new);
    // Pre-warm the synchronous CourierStorage.getOnline() read; fire and
    // forget is safe (see CourierStorage docs).
    CourierStorage.init();
  }

  static void _put<T extends Object>(GetIt getIt, T Function() build) {
    if (!getIt.isRegistered<T>()) getIt.registerSingleton<T>(build());
  }
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

DriverLoadRepositoryFacade get loadRepository =>
    _getIt.get<DriverLoadRepositoryFacade>();

DriverPoiRepositoryFacade get poiRepository =>
    _getIt.get<DriverPoiRepositoryFacade>();

/// Registered by map_sdk's `MapSdkDependencies.register` (map_sdk is part of
/// every driver compose — driver.json).
DrawRepositoryFacade get drawRepository => _getIt.get<DrawRepositoryFacade>();

/// Registered by products_sdk's `ProductsSdkDependencies.register`.
GalleryRepositoryFacade get galleryRepository =>
    _getIt.get<GalleryRepositoryFacade>();

/// Registered by users_sdk's `UsersSdkDependencies.register`.
UserRepositoryFacade get userRepository => _getIt.get<UserRepositoryFacade>();
