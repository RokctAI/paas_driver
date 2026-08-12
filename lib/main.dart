// Host main for the composed driver shell. Shaped after base_sdk's
// templates/main.dart (all @generated marker blocks present, so the
// composer's update_main_dependencies()/update_boot_hooks()/
// update_di_hooks()/update_app_routes()/update_embedded_widgets() keep
// working) with the driver app's own startup preserved - on a first-ever
// compose the installer has no hash record and would otherwise clobber this
// file (the 760191c lesson), so the host copy is committed pre-shaped and
// the installer warn-skips it.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:workmanager/workmanager.dart';
// Deep theme import (not the base_sdk barrel - that arrives via the
// generated sdk-imports block; importing the barrel here too would produce
// a duplicate_import lint on every compose).
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:driver/domain/di/dependency_manager.dart';
import 'package:driver/presentation/app_widget.dart';
import 'package:driver/presentation/routes/zones_adapters.dart';

// @generated-sdk-imports-start
import 'package:base_sdk/base_sdk.dart';
import 'package:auth_sdk/auth_sdk.dart';
import 'package:calc_sdk/calc_sdk.dart';
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

// Wiring imports: each SDK manifest's app_routes / embedded_widgets /
// brand_hook entries may carry an "imports" list of FULL import lines; they
// land here (deduped, sorted) so the injected bodies' symbols resolve
// without any hand-written imports in this file.
// @generated-wiring-imports-start
import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/services/remote_config_service.dart';
import 'package:comms_sdk/src/common/presentation/pages/setting/language_page.dart';
import 'package:comms_sdk/src/common/services/firebase_background_handler.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_service.dart';
import 'package:driver/presentation/routes/app_router.dart';
import 'package:driver/presentation/routes/zones_adapters.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:revenue_sdk/src/driver/di/driver_revenue_di.dart';
import 'package:workmanager/workmanager.dart';
// @generated-wiring-imports-end

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

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Host-specific startup (kept through the compose flip): the splash is
  // held until the router decides where to go, and the workmanager isolate
  // backs the courier-location report above. The Firebase/FCM boot that
  // used to sit here moved into comms_sdk's "boot_hooks" declaration
  // (comms-firebase-fcm-boot) - it lands in the generated block below on
  // every compose, imports riding the wiring block. The workmanager line is
  // destined for a delivery_sdk boot_hook the same way.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Workmanager().initialize(callbackDispatcher);

  // Boot hooks: SDK-declared startup statements (each SDK manifest's
  // "boot_hooks" list - id-keyed, order-sequenced; see the installer's
  // update_boot_hooks()). comms_sdk declares the Firebase init + FCM
  // background handler here.
  // @generated-boot-hooks-start
  // auth_pending_otp_gate (order 0, from auth_sdk)
  PendingOtpGate.install();
  // delivery-driver-splash-preserve (order 1, from delivery_sdk)
  FlutterNativeSplash.preserve(
      widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
  // delivery-driver-courier-location-workmanager (order 5, from delivery_sdk)
  await Workmanager().initialize(callbackDispatcher);
  // comms-firebase-fcm-boot (order 10, from comms_sdk)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // base-remote-config-boot (order 20, from base_sdk)
  await RemoteConfigService.initialize(appType: 'Driver');
  // @generated-boot-hooks-end

  // Brand hook: at most ONE installed SDK (normally the home SDK) declares
  // "brand_hook" in its manifest and its call is injected here to load the
  // app's brand palette into the shared AppStyle tokens before the first
  // frame. The kernel ships neutral defaults only.
  // @generated-brandhook-start

  // @generated-brandhook-end

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
  // base_sdk's import and DI registration are injected into the generated
  // blocks (base_sdk first - update_main_dependencies() orders it ahead of
  // every feature SDK). Do NOT also import/register it by hand up here.
  // @generated-sdk-di-start
  BaseSdkDependencies.register(GetIt.instance);
  AuthSdkDependencies.register(GetIt.instance);
  CalcSdkDependencies.register(GetIt.instance);
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

  // DI hooks: SDK-declared DI statements beyond the standard
  // *SdkDependencies.register calls above (each SDK manifest's "di_hooks"
  // list; see the installer's update_di_hooks()). The hand-written host DI
  // and ADR-005 facade registrations below move here once delivery_sdk /
  // zones_sdk declare them (see scratchpad/di-hooks-declarations.md in the
  // migration PR set).
  // @generated-di-hooks-start
  // revenue-driver-role-di (order 12, from revenue_sdk)
  DriverRevenueDependencies.register(GetIt.instance);
  // zones-driver-delivery-zones-facade (order 30, from zones_sdk)
  if (!GetIt.instance.isRegistered<DeliveryZonesFacade>()) {
    GetIt.instance.registerLazySingleton<DeliveryZonesFacade>(
        () => DriverDeliveryZonesAdapter());
  }
  if (!GetIt.instance.isRegistered<ZoneEditPolicy>()) {
    GetIt.instance
        .registerLazySingleton<ZoneEditPolicy>(() => DriverZoneEditPolicy());
  }
  // @generated-di-hooks-end

  // ---- Host-owned DI ----
  // Deliberately OUTSIDE the generated block: update_sdk_di() rewrites
  // everything between the markers on every compose, so anything placed
  // inside is silently lost. The installer detects hand edits to main.dart
  // and stops overwriting the file, which is what keeps this section alive.

  // The last host-owned registrations (migration M3): the delivery-zone
  // slice of the old user repository, still resolved by zones_sdk's
  // installed adapter via di.userRepository, plus the driver-role revenue
  // DI - see dependency_manager.dart for the exit plan. Must run before the
  // adapters below, which resolve UserRepository. The host auth vertical
  // that used to register here died with the auth flip; auth_sdk registers
  // its own repositories in the generated DI block above.
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
  // directly. Methods are injected per-SDK from each manifest's "app_routes"
  // list (e.g. delivery_sdk declares replaceLoginRoute for base_sdk's
  // splash); anything not injected keeps throwing a descriptive StateError
  // via noSuchMethod rather than failing silently.
  //
  // EmbeddedWidgets.I: same indirection for host-composed widgets - SDK code
  // renders another SDK's pages/widgets through it without importing that
  // SDK directly (ADR-005), e.g. comms_sdk's language screen.
  EmbeddedWidgets.I = _HostEmbeddedWidgets();
  AppRoutes.I = _HostAppRoutes();

  runApp(const ProviderScope(child: AppWidget()));
}

class _HostEmbeddedWidgets implements EmbeddedWidgets {
  // @generated-embeddedwidgets-start
  @override
  Widget languageScreen({required VoidCallback onSave}) {
    return LanguageScreen(onSave: onSave);
  }

  @override
  Widget policyPage() {
    return const PolicyPage();
  }

  @override
  Widget termPage() {
    return const TermPage();
  }

  // @generated-embeddedwidgets-end

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
      'EmbeddedWidgets.I.${invocation.memberName} has not been implemented — '
      'no installed SDK declares it in "embedded_widgets", and it was not '
      'added by hand in main.dart.');
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

  @override
  Future<Object?> replaceLoginRoute(BuildContext context) =>
      context.router.replace(LoginRoute());

  @override
  Future<Object?> replaceMainRoute(BuildContext context) =>
      context.router.replace(HomeRoute());

  // @generated-approutes-end

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
      'AppRoutes.I.${invocation.memberName} has not been implemented — no '
      'installed SDK declares it in "app_routes", and it was not added by '
      'hand in main.dart.');
}
