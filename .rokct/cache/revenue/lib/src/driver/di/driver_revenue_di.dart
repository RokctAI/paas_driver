import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/courier_statistics_repository.dart';

/// Driver-role DI hook. Not exported by the barrel — the common
/// `RevenueSdkDependencies.register` cannot import this file because a
/// manager app's cache has `lib/src/driver/` stripped. The manifest's
/// app_type.driver `di_hooks` entry injects the call into the generated
/// main.dart via this direct `src/` path (driver migration M4; a host mid
/// migration may still call it from its own DI setup too). Registers
/// idempotently so both call sites can coexist.
class DriverRevenueDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<CourierStatisticsRepositoryFacade>()) {
      getIt.registerSingleton<CourierStatisticsRepositoryFacade>(
        CourierStatisticsRepository(),
      );
    }
  }
}
