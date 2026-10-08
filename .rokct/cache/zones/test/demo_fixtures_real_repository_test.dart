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

// Demo runs the REAL DriverDeliveryZonesRepository (through the installed
// driver adapter): base_sdk's DemoGatewayInterceptor answers the zone cmds
// from templates/assets/demo/zones/<cmd>.json while a demo session is on.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart'
    show DemoFixtures, DemoSession, HttpService, LocalStorage, getIt;
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zones_sdk/zones_sdk.dart';

import '../templates/adapters/driver/zones_adapters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
    await DemoSession.instance.activate();
    if (!getIt.isRegistered<HttpService>()) {
      getIt.registerSingleton<HttpService>(HttpService());
    }
    DemoFixtures.reset();
    DemoFixtures.loader = (key) async {
      final f = File(key.replaceFirst(
          '$zonesDemoFixtureDirectory/', 'templates/assets/demo/zones/'));
      return f.existsSync() ? f.readAsString() : null;
    };
    ZonesSdkDependencies.register(GetIt.asNewInstance());
  });

  tearDown(() async {
    DemoFixtures.reset();
    await DemoSession.instance.clear();
  });

  test('the real repository reads the demo zone from the fixture', () async {
    final ApiResult<List<List<double>>> result =
        await DriverDeliveryZonesAdapter().fetchDeliveryZones();
    final ring = (result as Success<List<List<double>>>).data;
    expect(ring, hasLength(5));
    expect(ring.first, ring.last);
  });

  test('a redraw is acknowledged by the fixture, never the wire', () async {
    final ApiResult<void> saved = await DriverDeliveryZonesAdapter()
        .updateDeliveryZones(points: const <List<double>>[
      [-26.10, 28.00],
      [-26.10, 28.08],
      [-26.16, 28.08],
    ]);
    expect(saved, isA<Success<void>>());
  });

  test('no Demo* repository or isDemo read remains', () {
    for (final f in <FileSystemEntity>[
      ...Directory('lib').listSync(recursive: true),
      ...Directory('templates').listSync(recursive: true),
    ].whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final src = f.readAsStringSync();
      expect(src.contains('AppConstants.isDemo'), isFalse, reason: f.path);
      expect(src.contains('DemoDriverDeliveryZonesRepository'), isFalse,
          reason: f.path);
    }
  });
}
