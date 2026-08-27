// Copyright (c) 2026 RokctAI
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

import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/services/connectivity_service.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';

/// Kernel registrations every composed app needs.
///
/// Called from the host app's `main()` (the installer generates the call for
/// composed apps; hand-wired hosts call it directly) BEFORE any feature
/// SDK's `*SdkDependencies.register`. Requires [LocalStorage.init] to have
/// completed.
class BaseSdkDependencies {
  static void register(GetIt getIt) {
    if (!getIt.isRegistered<HttpService>()) {
      getIt.registerLazySingleton<HttpService>(() => HttpService());
    }
    if (!getIt.isRegistered<Map>()) {
      getIt.registerSingleton<Map>(LocalStorage.getTranslations());
    }
    // Registered before feature SDKs so their *SdkDependencies.register can
    // resolve the engine and attach SyncHandlers.
    if (!getIt.isRegistered<SyncEngine>()) {
      getIt.registerSingleton<SyncEngine>(SyncEngine());
    }
    // App-lifetime listener that drains the outbox on connectivity regain.
    ConnectivityService.I.start();
  }
}
