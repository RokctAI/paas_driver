import 'package:get_it/get_it.dart';

import '../domain/interface/processing_repository_facade.dart';
import '../infrastructure/services/local_processing_repository.dart';

class ProcessingSdkDependencies {
  /// Registers the offline default. Hosts that persist contract state on a
  /// backend register their own [ProcessingRepositoryFacade] BEFORE calling
  /// this (an existing registration is left untouched).
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<ProcessingRepositoryFacade>()) {
      getIt.registerLazySingleton<ProcessingRepositoryFacade>(
        () => LocalProcessingRepository(),
      );
    }
  }
}
