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

// Starts a demo session whose platform calls base_sdk's
// DemoGatewayInterceptor answers from templates/assets/demo/revenue, the
// same fixtures a composed host installs at assets/demo/revenue.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart'
    show DemoFixtures, DemoSession, HttpService, LocalStorage, getIt;
import 'package:revenue_sdk/src/common/di/revenue_di.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> startRevenueDemoSession() async {
  SharedPreferences.setMockInitialValues({});
  await LocalStorage.init();
  await DemoSession.instance.activate();
  if (!getIt.isRegistered<HttpService>()) {
    getIt.registerSingleton<HttpService>(HttpService());
  }
  DemoFixtures.reset();
  // Read up front, synchronously: widget tests run in fake async, where
  // real file I/O never completes, so the loader answers from memory.
  final fixtures = <String, String>{
    for (final f in Directory('templates/assets/demo/revenue')
        .listSync()
        .whereType<File>())
      '$revenueDemoFixtureDirectory/${f.uri.pathSegments.last}':
          f.readAsStringSync(),
  };
  DemoFixtures.loader = (key) async => fixtures[key];
  DemoFixtures.registerAssetDirectory(revenueDemoFixtureDirectory);
}

Future<void> endRevenueDemoSession() async {
  DemoFixtures.reset();
  await DemoSession.instance.clear();
}
