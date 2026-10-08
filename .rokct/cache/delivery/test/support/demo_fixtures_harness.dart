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

// Starts a demo session whose platform-gateway calls base_sdk's
// DemoGatewayInterceptor answers from templates/assets/demo/delivery, so a
// test drives the REAL repositories through the real HttpService stack.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart'
    show DemoFixtures, DemoSession, HttpService, LocalStorage, getIt;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';

/// Per-cmd overrides a test may set (raw JSON text, or null for "missing").
final Map<String, String?> demoFixtureOverrides = <String, String?>{};

Future<void> startDemoFixtures() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await LocalStorage.init();
  await DemoSession.instance.activate();
  if (getIt.isRegistered<HttpService>()) {
    await getIt.unregister<HttpService>();
  }
  getIt.registerSingleton<HttpService>(HttpService());
  DemoFixtures.reset();
  demoFixtureOverrides.clear();
  DemoFixtures.loader = (key) async {
    final String cmd = key.split('/').last.replaceAll(RegExp(r'\.json$'), '');
    if (demoFixtureOverrides.containsKey(cmd)) {
      return demoFixtureOverrides[cmd];
    }
    final f = File(key.replaceFirst('$deliveryDemoFixtureDirectory/',
        'templates/assets/demo/delivery/'));
    return f.existsSync() ? f.readAsStringSync() : null;
  };
  DemoFixtures.registerAssetDirectory(deliveryDemoFixtureDirectory);
}

Future<void> stopDemoFixtures() async {
  DemoFixtures.reset();
  demoFixtureOverrides.clear();
  await DemoSession.instance.clear();
}
