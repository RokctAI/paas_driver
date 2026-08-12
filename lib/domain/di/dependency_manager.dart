// Shrunken in migration stage M2 to the host-owned registrations that must
// outlive the shared-layer swap:
//
//  - the host AUTH vertical (SettingsRepository for the login language
//    switcher, AuthRepository, and the UserRepository profile slice its
//    notifiers call) - all of it dies with the auth flip (M3), when
//    auth_sdk's installed flows and comms_sdk's settings facade take over;
//  - the UserRepository seam zones_sdk's installed driver adapter
//    (lib/presentation/routes/zones_adapters.dart) resolves via
//    `di.userRepository` for the courier's delivery-zone polygon. This
//    outlives M3 and dies once the adapter is rewritten against a users_sdk
//    repository or the registration moves to a `di_hooks` manifest
//    declaration (The-Rokct-Protocol#160) - the M4 exit plan.
//
// Everything else the old setUpDependencies() registered is SDK-owned now:
// base_sdk registers HttpService, and the courier orders/parcel/draw/
// notification repositories moved into delivery_sdk / map_sdk / comms_sdk
// with their verticals (each registers its own DI in the @generated-sdk-di
// block in main.dart).
import 'package:get_it/get_it.dart';

import '../../infrastructure/repositories/auth_repository_impl.dart';
import '../../infrastructure/repositories/settings_repository_impl.dart';
import '../../infrastructure/repositories/user_repository_impl.dart';
import '../../presentation/routes/app_router.dart';
import '../interface/interfaces.dart';
import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:revenue_sdk/revenue_sdk.dart';
// Direct src/ import by design: DriverRevenueDependencies is role code, kept
// out of the barrel so a manager app's stripped cache still compiles it.
import 'package:revenue_sdk/src/driver/di/driver_revenue_di.dart';

final GetIt getIt = GetIt.instance;

Future<void> setUpDependencies() async {
  // HttpService is registered by BaseSdkDependencies.register() in main(),
  // which runs first and guards on isRegistered. Registering it again here
  // with registerSingleton (unguarded) would throw on startup.
  if (!getIt.isRegistered<HttpService>()) {
    getIt.registerSingleton<HttpService>(HttpService());
  }
  getIt.registerSingleton<SettingsRepository>(SettingsRepositoryImpl());
  getIt.registerSingleton<AuthRepository>(AuthRepositoryImpl());
  getIt.registerSingleton<UserRepository>(UserRepositoryImpl());
  getIt.registerSingleton<AppRouter>(AppRouter());
  // Driver-role revenue registrations. RevenueSdkDependencies.register (still
  // called from main()'s generated DI block) is an empty common hook now that
  // both concrete repositories are strippable role code — the host wires its
  // own role's DI explicitly.
  DriverRevenueDependencies.register(getIt);
}

final dioHttp = getIt.get<HttpService>();
final settingsRepository = getIt.get<SettingsRepository>();
final authRepository = getIt.get<AuthRepository>();
final userRepository = getIt.get<UserRepository>();
final appRouter = getIt.get<AppRouter>();

// SDK-owned repository, registered by DriverRevenueDependencies.register() in
// setUpDependencies() above — exposed here so the surviving host code (the
// profile-settings notifier the register funnel still uses) resolves it the
// same way as the app's own repositories.
final courierStatisticsRepository =
    getIt.get<CourierStatisticsRepositoryFacade>();
