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
import 'package:base_sdk/src/handlers/demo_gateway_interceptor.dart';
import 'package:map_sdk/src/common/domain/interface/customer_poi.dart';
import 'package:map_sdk/src/common/infrastructure/repositories/customer_poi_repository.dart';
import 'package:map_sdk/src/common/infrastructure/repositories/draw_repository.dart';
import 'package:map_sdk/src/common/infrastructure/services/places/places_service.dart';

/// Host asset directory holding map_sdk's demo platform fixtures
/// (`<cmd>.json`), installed from `templates/assets/demo/map`.
const String mapDemoFixtureDirectory = 'assets/demo/map';

/// Installer-convention DI hook (see base_sdk BaseSdkDependencies).
class MapSdkDependencies {
  static void register(GetIt getIt) {
    // Demo runs the REAL repositories: base_sdk's DemoGatewayInterceptor
    // answers api.poi.get_customer_pois from this directory (an empty
    // list - an offline map stands no unapproved place on itself).
    DemoFixtures.registerAssetDirectory(mapDemoFixtureDirectory);
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
    if (!getIt.isRegistered<CustomerPoiRepositoryFacade>()) {
      getIt.registerSingleton<CustomerPoiRepositoryFacade>(
        CustomerPoiRepository(),
      );
    }
  }
}
