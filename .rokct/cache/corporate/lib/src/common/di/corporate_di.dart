import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/domain/interface/blogs.dart';
import 'package:corporate_sdk/src/common/infrastructure/repositories/blogs_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `CorporateSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class CorporateSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<BlogsRepositoryFacade>()) {
      getIt.registerSingleton<BlogsRepositoryFacade>(BlogsRepository());
    }
  }
}
