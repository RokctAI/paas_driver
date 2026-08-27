// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
