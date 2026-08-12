// Shrunken to the two host-owned registrations that outlive the auth flip
// (migration stage M3):
//
//  - the UserRepository seam zones_sdk's installed driver adapter
//    (lib/presentation/routes/zones_adapters.dart) resolves via
//    `di.userRepository` for the courier's delivery-zone polygon. This dies
//    once the adapter is rewritten against a users_sdk repository or the
//    registration moves to a `di_hooks` manifest declaration
//    (The-Rokct-Protocol#160) - the M4 exit plan;
//  - the driver-role revenue DI (DriverRevenueDependencies), which registers
//    CourierStatisticsRepositoryFacade for the installed profile/income
//    pages. It moves to a revenue_sdk `di_hooks` declaration on the same
//    timeline (see scratchpad/di-hooks-declarations.md in the migration PR
//    set).
//
// Everything else the old setUpDependencies() registered is SDK-owned now:
// base_sdk registers HttpService, auth_sdk owns the auth repositories (the
// host AuthRepository/SettingsRepository died with the flip), and the
// courier orders/parcel/draw/notification repositories live in
// delivery_sdk / map_sdk / comms_sdk (each registers its own DI in the
// @generated-sdk-di block in main.dart). The AppRouter registration is gone
// too: app_widget.dart now owns its router instance, template-style, and
// no surviving code resolves AppRouter through GetIt.
import 'package:get_it/get_it.dart';

import '../../infrastructure/repositories/user_repository_impl.dart';
import '../interface/user_repository.dart';
import 'package:revenue_sdk/revenue_sdk.dart';
// Direct src/ import by design: DriverRevenueDependencies is role code, kept
// out of the barrel so a manager app's stripped cache still compiles it.
import 'package:revenue_sdk/src/driver/di/driver_revenue_di.dart';

final GetIt getIt = GetIt.instance;

Future<void> setUpDependencies() async {
  if (!getIt.isRegistered<UserRepository>()) {
    getIt.registerSingleton<UserRepository>(UserRepositoryImpl());
  }
  // Driver-role revenue registrations. RevenueSdkDependencies.register (still
  // called from main()'s generated DI block) is an empty common hook now that
  // both concrete repositories are strippable role code — the host wires its
  // own role's DI explicitly. Idempotent (isRegistered-guarded internally).
  DriverRevenueDependencies.register(getIt);
}

final userRepository = getIt.get<UserRepository>();
