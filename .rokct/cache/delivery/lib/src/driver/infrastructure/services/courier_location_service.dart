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

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// Workmanager task id for the periodic courier-location report.
///
/// The courier home page registers/cancels the periodic task with this id
/// when the courier toggles online/offline; [callbackDispatcher] handles the
/// actual report. Both lived in paas_driver's tracked main.dart until driver
/// migration M4 — as the courier vertical's owner, delivery_sdk is their
/// home (the same reasoning that put comms_sdk's
/// firebaseMessagingBackgroundHandler into package code, manager M5).
const String fetchBackground = 'fetchBackground';

/// Reports the courier's position while the app is backgrounded.
///
/// Wired at boot by the manifest's app_type.driver `boot_hooks` entry
/// (`await Workmanager().initialize(callbackDispatcher);`). It must be a
/// TOP-LEVEL function: Workmanager invokes it by entry-point reference in a
/// separate isolate, so a host-private function inside main.dart could never
/// be referenced from an injected hook body. The `vm:entry-point` pragma
/// keeps the symbol alive through AOT tree-shaking — in release builds only
/// the native plugin references it.
///
/// Without this the driver app silently stops reporting location the moment
/// it leaves the foreground, which is the one thing dispatch depends on.
///
/// Posts directly with a raw Dio client rather than through a repository:
/// it runs in a separate isolate with no GetIt registrations, so it cannot
/// reach the composed DI graph (which is also why it builds the universal
/// platform gateway request by hand — same [kPlatformGatewayPath] and
/// `{"cmd", "payload"}` body shape as [PlatformGateway], same base URL and
/// token retrieval as before, without the DI-resolved HttpService).
/// Rewired from the dead legacy
/// `/api/v1/dashboard/deliveryman/settings/location` path to the working
/// Frappe endpoint (prefix-free cmd `api.driver.update_location` per map's
/// manifest), which writes Deliveryman Profile.latitude/longitude — the
/// position the server-side route optimizer starts from.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case fetchBackground:
        final LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );

        Position userLocation = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );

        final Dio client = Dio(
          BaseOptions(
            // Same 30s bounds base_sdk's HttpService sets on its central
            // BaseOptions; this isolate cannot reach that DI-resolved client.
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Accept':
                  'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
              'Content-type': 'application/json',
              "Authorization": "Bearer ${LocalStorage.getToken()}"
            },
          ),
        );
        await client.post(
          '${AppConstants.baseUrl}$kPlatformGatewayPath',
          data: {
            "cmd": "api.driver.update_location",
            "payload": {
              "latitude": userLocation.latitude,
              "longitude": userLocation.longitude,
            },
          },
        );
        break;
    }
    return Future.value(true);
  });
}
