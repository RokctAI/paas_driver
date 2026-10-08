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

// A demo session in a test: base_sdk's DemoGatewayInterceptor (on the
// real HttpService Dio stack) answers every platform cmd from this SDK's
// templates/assets/demo/merchants/<cmd>.json, read off the file system the
// way a host reads the installed assets/demo/merchants.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart'
    show DemoFixtures, DemoSession, HttpService, LocalStorage, getIt;
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts a demo session whose platform answers come from the fixtures.
///
/// [resetStorage] false keeps what the test already put in LocalStorage
/// (it must have been initialised).
Future<void> startDemoFixtures({bool resetStorage = true}) async {
  if (resetStorage) {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  }
  await DemoSession.instance.activate();
  if (!getIt.isRegistered<HttpService>()) {
    getIt.registerSingleton<HttpService>(HttpService());
  }
  DemoFixtures.reset();
  DemoFixtures.loader = (key) async {
    final f = File(
      key.replaceFirst(
        'assets/demo/merchants/',
        'templates/assets/demo/merchants/',
      ),
    );
    return f.existsSync() ? f.readAsString() : null;
  };
  DemoFixtures.registerAssetDirectory('assets/demo/merchants');
}

/// Ends the demo session started by [startDemoFixtures].
Future<void> stopDemoFixtures() async {
  DemoFixtures.reset();
  await DemoSession.instance.clear();
}

/// The success value of [result], or a test failure naming the error (a
/// missing fixture surfaces here as DemoFixtureMissing).
T ok<T>(ApiResult<T> result) => switch (result) {
  Success<T>(:final data) => data,
  Failure<T>(:final error) => throw StateError('demo call failed: $error'),
};
