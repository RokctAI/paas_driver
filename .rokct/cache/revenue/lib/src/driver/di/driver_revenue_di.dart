import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/driver/infrastructure/repositories/courier_statistics_repository.dart';

/// Driver-role DI hook. Not exported by the barrel and not called by the
/// generated `main.dart` — the common `RevenueSdkDependencies.register` cannot
/// import this file because a manager app's cache has `lib/src/driver/`
/// stripped. A driver host calls this from its own DI setup (e.g.
/// paas_driver's `setUpDependencies()`), importing it via this direct `src/`
/// path. Registers idempotently so hand-wired hosts can call it too.
class DriverRevenueDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<CourierStatisticsRepositoryFacade>()) {
      getIt.registerSingleton<CourierStatisticsRepositoryFacade>(
        CourierStatisticsRepository(),
      );
    }
  }
}
