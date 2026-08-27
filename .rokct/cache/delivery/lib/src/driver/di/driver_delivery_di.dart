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

import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/http_service.dart';

import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_parcel_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_route_repository.dart';
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
class DriverDeliveryDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<HttpService>()) {
      getIt.registerSingleton<HttpService>(HttpService());
    }
    // Demo mode (--dart-define=IS_DEMO=true) swaps every courier facade for
    // its Demo* twin serving DemoDeliverySeed data offline — the same
    // isDemo split auth_sdk's MockAuthRepository and lms_sdk's
    // DemoLmsRepository use. Zero behavior change when IS_DEMO is off, and
    // a host may still pre-register its own implementations before this
    // runs (idempotent guards below).
    final bool isDemo = AppConstants.isDemo;
    if (!getIt.isRegistered<CourierOrdersRepositoryFacade>()) {
      getIt.registerSingleton<CourierOrdersRepositoryFacade>(
        isDemo ? DemoCourierOrdersRepository() : CourierOrdersRepository(),
      );
    }
    if (!getIt.isRegistered<CourierParcelRepositoryFacade>()) {
      getIt.registerSingleton<CourierParcelRepositoryFacade>(
        isDemo ? DemoCourierParcelRepository() : CourierParcelRepository(),
      );
    }
    if (!getIt.isRegistered<CourierRepositoryFacade>()) {
      getIt.registerSingleton<CourierRepositoryFacade>(
        isDemo ? DemoCourierRepository() : CourierRepository(),
      );
    }
    if (!getIt.isRegistered<CourierRouteRepositoryFacade>()) {
      getIt.registerSingleton<CourierRouteRepositoryFacade>(
        isDemo ? DemoCourierRouteRepository() : CourierRouteRepository(),
      );
    }
    // Pre-warm the synchronous CourierStorage.getOnline() read; fire and
    // forget is safe (see CourierStorage docs).
    CourierStorage.init();
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

/// Registered by map_sdk's `MapSdkDependencies.register` (map_sdk is part of
/// every driver compose — driver.json).
DrawRepositoryFacade get drawRepository => _getIt.get<DrawRepositoryFacade>();

/// Registered by products_sdk's `ProductsSdkDependencies.register`.
GalleryRepositoryFacade get galleryRepository =>
    _getIt.get<GalleryRepositoryFacade>();

/// Registered by users_sdk's `UsersSdkDependencies.register`.
UserRepositoryFacade get userRepository => _getIt.get<UserRepositoryFacade>();
