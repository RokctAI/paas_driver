import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:auth_sdk/src/common/infrastructure/repositories/auth_repository.dart';
import 'package:auth_sdk/src/common/infrastructure/repositories/mock_auth_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `AuthSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class AuthSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<AuthRepositoryFacade>()) {
      getIt.registerSingleton<AuthRepositoryFacade>(
        AppConstants.isDemo ? MockAuthRepository() : AuthRepository(),
      );
    }
  }
}
