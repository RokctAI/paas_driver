import 'package:get_it/get_it.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `RevenueSdkDependencies.register(GetIt.instance)` for every installed
/// SDK, importing it through the barrel — so this file must compile in every
/// role-stripped cache and cannot import anything under `lib/src/manager/` or
/// `lib/src/driver/` (the composer's strip_unused_role_folders deletes the
/// non-matching role folder from an app's cache).
///
/// The concrete repositories are role code, so their registration lives with
/// them: `ManagerRevenueDependencies` (src/manager/di/manager_revenue_di.dart)
/// registers [SellerStatisticsRepositoryFacade] and `DriverRevenueDependencies`
/// (src/driver/di/driver_revenue_di.dart) registers
/// [CourierStatisticsRepositoryFacade]. The host app calls its own role's hook
/// from its DI setup via a direct `src/` import — same stance as zones_sdk's
/// empty `ZonesSdkDependencies.register`, where role wiring is the host's to
/// supply. A host that skips it fails at first resolve of the facade, loudly,
/// not at compile time.
class RevenueSdkDependencies {
  static void register(GetIt getIt) {
    // Intentionally empty — see class doc. Role repositories are registered
    // by the host calling its role's hook, e.g. a driver app:
    //
    //   DriverRevenueDependencies.register(getIt);
  }
}
