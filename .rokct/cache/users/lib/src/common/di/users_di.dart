import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/address.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/user_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/address_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/mock_address_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `UsersSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class UsersSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<UserRepositoryFacade>()) {
      getIt.registerSingleton<UserRepositoryFacade>(UserRepository());
    }
    if (!getIt.isRegistered<AddressRepositoryFacade>()) {
      getIt.registerSingleton<AddressRepositoryFacade>(
        AppConstants.isDemo ? MockAddressRepository() : AddressRepository(),
      );
    }
  }
}
