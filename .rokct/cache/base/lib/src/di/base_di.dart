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


import 'dart:async';

import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/handlers/http_service.dart';
import 'package:base_sdk/src/services/connectivity_service.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/memory_pressure_service.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:base_sdk/src/utils/app_usage_service.dart';

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

    // Size the image cache from the device's actual RAM instead of Flutter's
    // fixed 1000 images / 100MB, and start listening for memory pressure and
    // backgrounding. Registered here rather than in the generated main.dart
    // so every composed app picks it up from a base_sdk bump alone.
    // Fire-and-forget and internally exception-guarded, exactly like the
    // usage event below: it can only ever lower a cache ceiling, so failing
    // to attach leaves the app where it is today rather than breaking it.
    unawaited(MemoryPressureService().start());

    // Once-daily `app_open` usage event (Ray-approved telemetry cadence:
    // one direct event per day, not per foreground). This is the one
    // bootstrap path every composed app hits (generated main.dart's
    // @generated-sdk-di block, ordered first), after LocalStorage.init and
    // with HttpService registered just above — so the track lane can
    // deliver. Fire-and-forget and internally exception-guarded: usage
    // telemetry must never break or delay bootstrap. Anonymous launches
    // no-op inside (the lane is auth-required).
    unawaited(AppUsageService.recordAppOpenIfNeeded());
  }
}
