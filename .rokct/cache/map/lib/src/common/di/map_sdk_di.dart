import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:map_sdk/src/common/infrastructure/repositories/draw_repository.dart';
import 'package:map_sdk/src/common/infrastructure/services/places/places_service.dart';

/// Installer-convention DI hook (see base_sdk BaseSdkDependencies).
class MapSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<DrawRepositoryFacade>()) {
      getIt.registerSingleton<DrawRepositoryFacade>(DrawRepository());
    }
    if (!getIt.isRegistered<GooglePlacesService>()) {
      getIt.registerSingleton<GooglePlacesService>(
        GooglePlacesService(dio: Dio(), apiKey: AppConstants.googleApiKey),
      );
    }
  }
}
