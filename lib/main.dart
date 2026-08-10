// ==========================================
// [GENERATED TEMPLATE FILE]
// This file was installed from: base_sdk
// Feel free to modify and customize this code.
// Note: If you edit this file, the SDK installer will detect your changes
// and automatically skip overwriting it during future upgrades.
// ==========================================

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:workmanager/workmanager.dart';
import 'package:base_sdk/base_sdk.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:driver/presentation/app_widget.dart';
import 'package:driver/presentation/routes/app_router.dart';
import 'package:driver/domain/di/dependency_manager.dart';
import 'package:driver/presentation/routes/zones_adapters.dart';

// @generated-sdk-imports-start
import 'package:base_sdk/base_sdk.dart';
import 'package:comms_sdk/comms_sdk.dart';
import 'package:corporate_sdk/corporate_sdk.dart';
import 'package:delivery_sdk/delivery_sdk.dart';
import 'package:map_sdk/map_sdk.dart';
import 'package:merchants_sdk/merchants_sdk.dart';
import 'package:orders_sdk/orders_sdk.dart';
import 'package:processing_sdk/processing_sdk.dart';
import 'package:products_sdk/products_sdk.dart';
import 'package:revenue_sdk/revenue_sdk.dart';
import 'package:users_sdk/users_sdk.dart';
import 'package:zones_sdk/zones_sdk.dart';
// @generated-sdk-imports-end

/// Workmanager task id for the periodic courier-location report.
const fetchBackground = "fetchBackground";

/// Reports the courier's position while the app is backgrounded.
///
/// Restored after the first compose replaced this file with base_sdk's
/// template - the installer's overwrite guard could not fire on a first-ever
/// compose, so all host-specific startup was lost (see also Firebase init and
/// the splash hold below). Without this the driver app silently stops
/// reporting location the moment it leaves the foreground, which is the one
/// thing dispatch depends on.
///
/// Still posts to the legacy /api/v1 path directly rather than through a
/// repository: it runs in a separate isolate with no GetIt registrations, so
/// it cannot reach the composed DI graph. Endpoint recorded in
/// docs/fork-endpoint-handoff.md; moving this into delivery_sdk needs an
/// isolate-safe entry point and is out of scope for a frontend fork.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case fetchBackground:
        final LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );

        Position userLocation = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );

        final Dio client = Dio(
          BaseOptions(
            headers: {
              'Accept':
                  'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
              'Content-type': 'application/json',
              "Authorization": "Bearer ${LocalStorage.getToken()}"
            },
          ),
        );
        await client.post(
          '${AppConstants.baseUrl}/api/v1/dashboard/deliveryman/settings/location',
          data: {
            "location":
                "{'latitude': '${userLocation.latitude}', 'longitude': '${userLocation.longitude}'}"
          },
        );
        break;
    }
    return Future.value(true);
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Host-specific startup, also lost to the first compose. Firebase must be
  // initialized before anything touches messaging, and the splash is held
  // until AppWidget decides where to route.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();
  await Workmanager().initialize(callbackDispatcher);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppStyle.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppStyle.transparent,
      systemNavigationBarDividerColor: AppStyle.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await LocalStorage.init();
  BaseSdkDependencies.register(GetIt.instance);
  // @generated-sdk-di-start
  BaseSdkDependencies.register(GetIt.instance);
  CommsSdkDependencies.register(GetIt.instance);
  CorporateSdkDependencies.register(GetIt.instance);
  DeliverySdkDependencies.register(GetIt.instance);
  MapSdkDependencies.register(GetIt.instance);
  MerchantsSdkDependencies.register(GetIt.instance);
  OrdersSdkDependencies.register(GetIt.instance);
  ProcessingSdkDependencies.register(GetIt.instance);
  ProductsSdkDependencies.register(GetIt.instance);
  RevenueSdkDependencies.register(GetIt.instance);
  UsersSdkDependencies.register(GetIt.instance);
  ZonesSdkDependencies.register(GetIt.instance);
// @generated-sdk-di-end

  // ---- Host-owned DI ----
  // Deliberately OUTSIDE the generated block: update_sdk_di() rewrites
  // everything between the markers on every compose, so anything placed
  // inside is silently lost. The installer detects hand edits to main.dart
  // and stops overwriting the file, which is what keeps this section alive.

  // The driver app's own repositories (UserRepository, OrdersRepositoryFacade,
  // ParcelRepositoryFacade, ...). base_sdk's main.dart template knows nothing
  // about them, so without this call every `getIt.get<...>` in
  // dependency_manager.dart throws on first access. Must run before the
  // adapters below, which resolve UserRepository.
  await setUpDependencies();

  // zones_sdk declares DeliveryZonesFacade and ZoneEditPolicy but registers
  // neither - by design, since only the host knows which repository stores the
  // courier's zone and what may restrict editing (ADR-005). Unregistered,
  // deliveryZoneProvider falls back to a 501 "not wired" stand-in and the
  // delivery-zone screen never reaches real profile data.
  GetIt.instance.registerLazySingleton<DeliveryZonesFacade>(
    () => DriverDeliveryZonesAdapter(),
  );
  GetIt.instance.registerLazySingleton<ZoneEditPolicy>(
    () => DriverZoneEditPolicy(),
  );

  // AppRoutes.I: SDK-resident code (splash, auth flows) navigates through
  // this indirection since it can't reference host-generated route classes
  // directly. Methods below this line are injected per-SDK (see each SDK's
  // manifest.json "app_routes" list, e.g. auth_sdk declares
  // replaceLoginRoute) — a method only appears here if some installed SDK
  // actually needs it. Anything not injected keeps throwing a descriptive
  // StateError via noSuchMethod rather than failing silently. If this
  // app needs routing behavior no SDK provides, edit this class directly —
  // the installer detects host edits to main.dart and stops overwriting it.
  AppRoutes.I = _HostAppRoutes();

  runApp(const ProviderScope(child: AppWidget()));
}

class _HostAppRoutes implements AppRoutes {
  // @generated-approutes-start
  @override
  Future<Object?> replaceSplashRoute(BuildContext context) =>
      context.router.replace(SplashRoute());

  @override
  Future<Object?> replaceNoConnectionRoute(BuildContext context) =>
      context.router.replace(NoConnectionRoute());

  @override
  Future<Object?> replaceClosedRoute(BuildContext context) =>
      context.router.replace(ClosedRoute());

  @override
  Future<Object?> replaceUiTypeRoute(BuildContext context) =>
      context.router.replace(UiTypeRoute());

  // @generated-approutes-end

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
      'AppRoutes.I.${invocation.memberName} has not been implemented — no '
      'installed SDK declares it in "app_routes", and it was not added by '
      'hand in main.dart.');
}
