import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:merchants_sdk/src/common/infrastructure/repositories/shops_repository.dart';
import 'package:merchants_sdk/src/common/infrastructure/repositories/mock_shops_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `MerchantsSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class MerchantsSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<ShopsRepositoryFacade>()) {
      getIt.registerSingleton<ShopsRepositoryFacade>(
        AppConstants.isDemo ? MockShopsRepository() : ShopsRepository(),
      );
    }
  }
}
