import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/http_service.dart';

import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/domain/interface/parcel.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/parcel_repository.dart';
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
    if (!getIt.isRegistered<CourierOrdersRepositoryFacade>()) {
      getIt.registerSingleton<CourierOrdersRepositoryFacade>(
        CourierOrdersRepository(),
      );
    }
    if (!getIt.isRegistered<CourierParcelRepositoryFacade>()) {
      getIt.registerSingleton<CourierParcelRepositoryFacade>(
        CourierParcelRepository(),
      );
    }
    if (!getIt.isRegistered<CourierRepositoryFacade>()) {
      getIt.registerSingleton<CourierRepositoryFacade>(CourierRepository());
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

/// Registered by map_sdk's `MapSdkDependencies.register` (map_sdk is part of
/// every driver compose — driver.json).
DrawRepositoryFacade get drawRepository => _getIt.get<DrawRepositoryFacade>();

/// Registered by products_sdk's `ProductsSdkDependencies.register`.
GalleryRepositoryFacade get galleryRepository =>
    _getIt.get<GalleryRepositoryFacade>();

/// Registered by users_sdk's `UsersSdkDependencies.register`.
UserRepositoryFacade get userRepository => _getIt.get<UserRepositoryFacade>();
