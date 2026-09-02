// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
      // The service resolves base_sdk's shared HttpService client lazily, so
      // no bare Dio() is constructed here (radio_sdk audit-2 precedent).
      getIt.registerSingleton<GooglePlacesService>(
        GooglePlacesService(apiKey: AppConstants.googleApiKey),
      );
    }
  }
}
