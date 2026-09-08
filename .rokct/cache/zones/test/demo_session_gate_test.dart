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

// Demo login phase 2: the installed driver zones adapter gates the offline
// zone on DemoSession.demoActive (base_sdk 1.61.0) - the compile-time
// IS_DEMO build OR the runtime session a server-marked account opens -
// per call, so the lazy singleton the di_hooks entry registers follows a
// flip with no re-registration.
//
// The adapter lives in templates/ (host-side code) but carries no
// ${package} import, so this package can exercise it directly. The real
// path resolves base_sdk's HttpService lazily from GetIt.instance, which
// this test leaves empty: it fails inside the repository's own try and
// answers a Failure, never a network call.

import 'dart:io';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zones_sdk/src/driver/infrastructure/repositories/demo_delivery_zones_repository.dart';

import '../templates/adapters/driver/zones_adapters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
    DemoSession.isDemoOverride = false;
  });

  tearDown(() async {
    await DemoSession.instance.clear();
    // The override is app-global; never let one test leak into the next.
    DemoSession.isDemoOverride = null;
  });

  Future<List<List<double>>> demoRing() async =>
      switch (await DemoDriverDeliveryZonesRepository().fetchDeliveryZones()) {
        Success(:final data) => data,
        Failure() => fail('the demo repository never fails'),
      };

  group('DriverDeliveryZonesAdapter', () {
    test('with the session off, the real path is taken', () async {
      final ApiResult<List<List<double>>> result =
          await DriverDeliveryZonesAdapter().fetchDeliveryZones();
      expect(result, isA<Failure<List<List<double>>>>());
    });

    test('activate serves the offline zone, clear returns to the real path',
        () async {
      final DriverDeliveryZonesAdapter adapter = DriverDeliveryZonesAdapter();

      await DemoSession.instance.activate();
      final ApiResult<List<List<double>>> demo =
          await adapter.fetchDeliveryZones();
      expect(demo, isA<Success<List<List<double>>>>());
      expect((demo as Success<List<List<double>>>).data, await demoRing());

      await DemoSession.instance.clear();
      final ApiResult<List<List<double>>> real =
          await adapter.fetchDeliveryZones();
      expect(real, isA<Failure<List<List<double>>>>());
    });

    test('a demo build serves the offline zone whatever the session says',
        () async {
      DemoSession.isDemoOverride = true;
      final ApiResult<List<List<double>>> result =
          await DriverDeliveryZonesAdapter().fetchDeliveryZones();
      expect(result, isA<Success<List<List<double>>>>());
    });

    test('an update in the session lands on the offline zone, not the wire',
        () async {
      await DemoSession.instance.activate();
      const List<List<double>> ring = <List<double>>[
        [-26.10, 28.00],
        [-26.10, 28.08],
        [-26.16, 28.08],
        [-26.16, 28.00],
      ];
      final ApiResult<void> saved =
          await DriverDeliveryZonesAdapter().updateDeliveryZones(points: ring);
      expect(saved, isA<Success<void>>());
      expect(await demoRing(), ring);
    });
  });

  group('source contract', () {
    Iterable<File> dartFilesUnder(String dir) => Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    test('no AppConstants.isDemo read remains in lib/ or templates/', () {
      final List<String> offenders = <String>[
        for (final file in [
          ...dartFilesUnder('lib'),
          ...dartFilesUnder('templates'),
        ])
          if (file.readAsStringSync().contains('AppConstants.isDemo'))
            file.path,
      ];
      expect(offenders, isEmpty);
    });

    test('the driver adapter asks DemoSession.demoActive on both overrides',
        () {
      final String src = File('templates/adapters/driver/zones_adapters.dart')
          .readAsStringSync();
      expect('DemoSession.demoActive'.allMatches(src).length,
          greaterThanOrEqualTo(2));
    });
  });
}
