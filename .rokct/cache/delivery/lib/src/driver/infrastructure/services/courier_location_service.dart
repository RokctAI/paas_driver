import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
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
/// Still posts to the legacy /api/v1 path directly rather than through a
/// repository: it runs in a separate isolate with no GetIt registrations, so
/// it cannot reach the composed DI graph. Endpoint recorded in paas_driver's
/// docs/fork-endpoint-handoff.md.
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
            headers: {
              'Accept':
                  'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
              'Content-type': 'application/json',
              "Authorization": "Bearer ${LocalStorage.getToken()}"
            },
          ),
        );
        await client.post(
          '${AppConstants.baseUrl}/api/v1/dashboard/deliveryman/settings/location',
          data: {
            "location":
                "{'latitude': '${userLocation.latitude}', 'longitude': '${userLocation.longitude}'}"
          },
        );
        break;
    }
    return Future.value(true);
  });
}
