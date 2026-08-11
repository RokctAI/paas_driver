import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/domain/interface/delivery_points.dart';
import 'package:delivery_sdk/src/common/infrastructure/repositories/delivery_points_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `DeliverySdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class DeliverySdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<DeliveryPointsRepositoryFacade>()) {
      getIt.registerSingleton<DeliveryPointsRepositoryFacade>(DeliveryPointsRepository());
    }
  }
}
