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


// A demo session whose platform calls base_sdk's DemoGatewayInterceptor
// answers from templates/assets/demo/auth - the fixtures a composed host
// installs at assets/demo/auth - so tests sign in through the REAL
// AuthRepository and its real HTTP stack.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart'
    show DemoFixtures, DemoSession, HttpService, LocalStorage, getIt;
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/src/common/di/auth_demo_fixtures.dart';
import 'package:auth_sdk/src/common/infrastructure/repositories/auth_repository.dart';

Future<void> startAuthDemoSession() async {
  SharedPreferences.setMockInitialValues({});
  await LocalStorage.init();
  await DemoSession.instance.activate();
  if (!getIt.isRegistered<HttpService>()) {
    getIt.registerSingleton<HttpService>(HttpService());
  }
  DemoFixtures.reset();
  final fixtures = <String, String>{
    for (final f in Directory('templates/assets/demo/auth')
        .listSync()
        .whereType<File>())
      '$authDemoFixtureDirectory/${f.uri.pathSegments.last}':
          f.readAsStringSync(),
  };
  DemoFixtures.loader = (key) async => fixtures[key];
  DemoFixtures.registerAssetDirectory(authDemoFixtureDirectory);
}

Future<void> endAuthDemoSession() async {
  DemoFixtures.reset();
  await DemoSession.instance.clear();
}

/// Signs in [email] through the real [AuthRepository] and returns the
/// account the (fixture-answered) backend handed back.
Future<UserModel> signInDemo(String email) async {
  final result = await AuthRepository().login(
    email: email,
    password: 'demo-learners-2026',
  );
  expect(result, isA<Success<LoginResponse>>());
  return (result as Success<LoginResponse>).data.data!.user!;
}
