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

// A driver who has no location permission must still get a working home
// page — pinned after the guided tour died on it.
//
// paas_driver tour 33623262696 reached driver_home and took the whole page
// down:
//
//   The following PermissionDeniedException was thrown running a test:
//   User denied permissions to access the device's location.
//   #0  GeolocatorAndroid.getCurrentPosition (...:140:7)
//   #1  _HomePageState.getMyLocation (.../home/home_page.dart:232:19)
//
// Frame #1 is the `else` arm of `getMyLocation()` — the one that runs when
// `check` is NOT `LocationPermission.denied`. On the boot path `check` is
// still `null`, because `initState` fires `checkPermission()` and
// `getMyLocation()` without awaiting either, so `getMyLocation` reaches
// `getCurrentPosition()` before anything has asked the OS for anything.
// Android then refuses the call outright — the tour's logcat shows no
// GrantPermissionsActivity and no ACCESS_*_LOCATION request against
// app.juvo.driver at all — and the exception escaped the un-awaited future.
//
// So the two things these tests hold down are:
//
//  1. NO refusal, at any permission state, may escape as an exception —
//     `CourierLocationFix.current()` always completes with a result and the
//     page keeps rendering on its fallback coordinates.
//  2. The refusal is REPORTED, not swallowed, and reported the fleet way
//     (decision-log entry 56): the driver sees one friendly translated line
//     and the verbatim platform detail goes to admins through
//     TelemetryClient. A stack trace, an error code or the raw
//     PermissionDeniedException text on a driver's screen is a failure.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_fix.dart';

/// The verbatim message geolocator_android raises for a refused fix.
const String _deniedMessage =
    "User denied permissions to access the device's location.";

/// A `Position` far from the demo fallback, so a test can tell a real fix
/// from the page's default coordinates.
final Position _fix = Position(
  latitude: -26.2041,
  longitude: 28.0473,
  timestamp: DateTime.utc(2026, 9, 2, 11, 10),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// A geolocator platform that answers exactly how the tour's emulator did.
///
/// Nothing here is stubbed at the level the code under test reads its
/// answer from: the permission getters return real [LocationPermission]
/// values and `getCurrentPosition` throws the real
/// [PermissionDeniedException], which is the only thing Android actually
/// tells the app when it refuses without raising a dialog.
class _FakeGeolocator extends GeolocatorPlatform {
  _FakeGeolocator({
    this.permission = LocationPermission.denied,
    this.requested,
    this.onPosition,
  });

  /// What `checkPermission()` reports.
  LocationPermission permission;

  /// What `requestPermission()` reports (defaults to [permission]).
  LocationPermission? requested;

  /// What `getCurrentPosition()` does. Refuses by default, so no test can
  /// pass by quietly getting a fix it was never entitled to.
  Position Function()? onPosition;

  int checkCalls = 0;
  int requestCalls = 0;
  int positionCalls = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    checkCalls++;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestCalls++;
    return requested ?? permission;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    positionCalls++;
    final produce = onPosition;
    if (produce == null) {
      throw const PermissionDeniedException(_deniedMessage);
    }
    return produce();
  }
}

/// A platform whose permission state reads fine but whose fix call is
/// refused — Android declining without ever presenting a dialog.
_FakeGeolocator _refusedByPlatform() => _FakeGeolocator(
      permission: LocationPermission.whileInUse,
      onPosition: () => throw const PermissionDeniedException(_deniedMessage),
    );

/// Pumps [child] under a real Overlay, which is what AppHelpers' top
/// snackbars render into.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
  });

  tearDown(() {
    TelemetryClient.configure(transport: null);
  });

  group('a refused fix never escapes as an exception', () {
    test('the tour case: boot-path call with nothing granted', () async {
      // Exactly initState — nothing has written a permission state yet, and
      // the emulator grants nothing. Before the fix this arrived at
      // `getCurrentPosition()` with a null permission state and the throw
      // escaped; now the state is established first and answered.
      final platform = _FakeGeolocator();

      final result = await CourierLocationFix(platform: platform).current();

      expect(result.hasFix, isFalse);
      expect(result.denial, CourierLocationDenial.permissionDenied);
      expect(result.detail, isNotNull);
    });

    test(
      'the platform refuses the call itself, whatever the state said',
      () async {
        // The narrow case the tour actually crashed on: the state read does
        // NOT say denied, and only the call itself refuses. This is the one
        // signal Android gives when it declines without raising a dialog, so
        // the catch around `getCurrentPosition` — not the state check — is
        // what has to hold.
        final platform = _refusedByPlatform();

        final result = await CourierLocationFix(platform: platform).current();

        expect(platform.positionCalls, greaterThan(0),
            reason: 'the refusal must come from the real platform call, '
                'not from a branch that never reaches it');
        expect(result.hasFix, isFalse);
        expect(result.denial, CourierLocationDenial.permissionDenied);
        expect(result.detail, contains(_deniedMessage),
            reason: 'the verbatim platform text is what admins need');
      },
    );

    test('the driver declines the prompt', () async {
      final platform = _FakeGeolocator(
        permission: LocationPermission.denied,
        requested: LocationPermission.denied,
      );

      final result = await CourierLocationFix(platform: platform).current();

      expect(result.hasFix, isFalse);
      expect(result.denial, CourierLocationDenial.permissionDenied);
      expect(platform.requestCalls, 1, reason: 'the driver is asked once');
    });

    test('permanently denied - no prompt can be raised any more', () async {
      final platform = _FakeGeolocator(
        permission: LocationPermission.deniedForever,
      );

      final result = await CourierLocationFix(platform: platform).current();

      expect(result.hasFix, isFalse);
      expect(result.denial, CourierLocationDenial.permissionDeniedForever);
      expect(platform.positionCalls, 0,
          reason: 'asking for a fix that cannot be granted is pointless');
    });

    test('location services switched off', () async {
      final platform = _FakeGeolocator(
        permission: LocationPermission.whileInUse,
        onPosition: () => throw const LocationServiceDisabledException(),
      );

      final result = await CourierLocationFix(platform: platform).current();

      expect(result.hasFix, isFalse);
      expect(result.denial, CourierLocationDenial.serviceDisabled);
    });

    test('granted - the fix still comes through untouched', () async {
      final platform = _FakeGeolocator(
        permission: LocationPermission.whileInUse,
        onPosition: () => _fix,
      );

      final result = await CourierLocationFix(platform: platform).current();

      expect(result.hasFix, isTrue);
      expect(result.position?.latitude, _fix.latitude);
      expect(result.position?.longitude, _fix.longitude);
      expect(result.denial, isNull);
    });
  });

  group('the refusal is reported, not swallowed', () {
    testWidgets(
      'the driver sees one friendly line and never the exception',
      (tester) async {
        final result = await CourierLocationFix(
          platform: _refusedByPlatform(),
        ).current();

        late BuildContext ctx;
        await _pump(tester, Builder(builder: (c) {
          ctx = c;
          return const SizedBox.shrink();
        }));

        CourierLocationNotice.show(ctx, result);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // The friendly line is the fleet's own translated copy for this
        // situation - the same key base_sdk's LocationService shows.
        final friendly = AppHelpers.getTranslation(TrKeys.agreeLocation);
        expect(friendly, isNotEmpty);
        expect(friendly, isNot(contains(_deniedMessage)));
        expect(find.text(friendly), findsOneWidget);

        // ...and nothing admin-grade reached the screen.
        expect(find.textContaining(_deniedMessage), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
        expect(find.textContaining('#0'), findsNothing);
        expect(find.textContaining('permissionDenied'), findsNothing);
      },
    );

    testWidgets('the verbatim detail reaches telemetry', (tester) async {
      final List<Map<String, dynamic>> sent = [];
      TelemetryClient.configure(transport: (cmd, payload) async {
        sent.add(payload);
      });

      final result = await CourierLocationFix(
        platform: _refusedByPlatform(),
      ).current();

      late BuildContext ctx;
      await _pump(tester, Builder(builder: (c) {
        ctx = c;
        return const SizedBox.shrink();
      }));

      CourierLocationNotice.show(ctx, result);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(sent, isNotEmpty, reason: 'a swallowed refusal is not a fix');
      // TelemetryClient's wire shape: {error_message: <type>, context:
      // <the JSON-encoded {type, timestamp, context} envelope>}.
      final event = sent.single;
      expect(event['error_message'], CourierLocationNotice.telemetryType);
      final envelope =
          jsonDecode(event['context'] as String) as Map<String, dynamic>;
      expect(envelope['type'], CourierLocationNotice.telemetryType);
      final logged = envelope['context'] as Map<String, dynamic>;
      expect('${logged['server_message']}', contains(_deniedMessage),
          reason: 'the detail admins need must survive verbatim');
      expect('${logged['denial']}',
          CourierLocationDenial.permissionDenied.name);
      expect('${logged['surface']}', 'driver_home');
    });
  });
}
