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

// An IS_DEMO build must open the driver home map on the seeded South
// African address, not on wherever the device happens to be.
//
// `_acquireLocation` (templates/pages/driver/home/home_page.dart) asked
// `CourierLocationFix.current()` for a fix like any other build, wrote it
// over the stored address and animated the map there — an emulator's
// default Californian coordinate, an ocean away from every seeded job. The
// gate now lives in CourierLocationFix so both of the page's lanes read
// it from one place. These tests hold down:
//
//  1. A pinned build NEVER reaches the platform — no permission check, no
//     prompt, no fix call.
//  2. Its answer is the stored address, else the seed's anchor, and it is
//     tagged `pinned` so the page does not write it back over storage.
//  3. A build that is not pinned is untouched: it still consults the
//     platform and its fix is not tagged.

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/services/local_storage.dart';

import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_delivery_seed.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_fix.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

/// The address the seed leaves in storage for the courier (Sandton).
const LatLng _stored = LatLng(-26.1076, 28.0567);

/// Far from both the stored address and the anchor, so a test can tell a
/// measured fix from a pinned one.
final Position _measured = Position(
  latitude: 37.4220,
  longitude: -122.0841,
  timestamp: DateTime.utc(2026, 9, 5, 9, 0),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// Counts every call the code under test makes to the platform. Permission
/// reads say "granted" and the fix call answers [_measured], so a build
/// that does reach the platform gets a real, distinguishable fix.
class _CountingPlatform extends GeolocatorPlatform {
  int calls = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    calls++;
    return LocationPermission.whileInUse;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    calls++;
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    calls++;
    return _measured;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
  });

  group('a pinned build', () {
    test('never asks the platform and stands at the stored address', () async {
      await CourierStorage.saveSelectedLocation(_stored);
      final platform = _CountingPlatform();

      final result =
          await CourierLocationFix(platform: platform, pinned: true).current();

      expect(platform.calls, 0,
          reason: 'no permission check, no prompt, no fix call');
      expect(result.hasFix, isTrue);
      expect(result.pinned, isTrue,
          reason: 'the page must know not to write this back to storage');
      expect(result.position!.latitude, _stored.latitude);
      expect(result.position!.longitude, _stored.longitude);
    });

    test('stands at the seed anchor when nothing is stored', () async {
      expect(LocalStorage.getAddressSelected(), isNull);
      final platform = _CountingPlatform();

      final result =
          await CourierLocationFix(platform: platform, pinned: true).current();

      expect(platform.calls, 0);
      expect(result.pinned, isTrue);
      expect(result.position!.latitude, DemoDeliverySeed.anchorLatitude);
      expect(result.position!.longitude, DemoDeliverySeed.anchorLongitude);
    });

    test('leaves storage exactly as it found it', () async {
      await CourierStorage.saveSelectedLocation(_stored);
      final before = LocalStorage.getAddressSelected();

      await CourierLocationFix(platform: _CountingPlatform(), pinned: true)
          .current();

      final after = LocalStorage.getAddressSelected();
      expect(after?.latitude, before?.latitude);
      expect(after?.longitude, before?.longitude);
    });
  });

  group('a build that is not pinned', () {
    test('still consults the platform and its fix is not tagged', () async {
      await CourierStorage.saveSelectedLocation(_stored);
      final platform = _CountingPlatform();

      final result =
          await CourierLocationFix(platform: platform, pinned: false).current();

      expect(platform.calls, greaterThan(0));
      expect(result.hasFix, isTrue);
      expect(result.pinned, isFalse);
      expect(result.position!.latitude, _measured.latitude);
      expect(result.position!.longitude, _measured.longitude);
    });

    test('is what a plain fix result reports', () {
      expect(CourierLocationResult.fix(_measured).pinned, isFalse);
      expect(
        const CourierLocationResult.unavailable(
          denial: CourierLocationDenial.lookupFailed,
          detail: '',
        ).pinned,
        isFalse,
      );
    });
  });
}
