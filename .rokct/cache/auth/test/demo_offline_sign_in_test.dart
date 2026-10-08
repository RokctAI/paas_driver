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

// Offline demo sign-in (Ray, 2026-10-03: "i didnt said remove existing
// features i only told you to use real repository files instead of mock
// repositories and use interceptions"). auth_sdk 1.13.0 signed the listed
// demo addresses in locally whatever the network; 1.14.0 dropped that with
// the mock repository. The listed addresses now switch the session to demo
// BEFORE the connectivity check, and the real AuthRepository is answered by
// base_sdk's DemoGatewayInterceptor from the auth fixtures - no network.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart'
    show DemoFixtures, DemoSession, HttpService, LocalStorage, getIt;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/src/common/di/auth_demo_fixtures.dart';
import 'package:auth_sdk/src/common/services/demo_sign_in.dart';

import 'support/auth_demo_fixtures.dart';

Future<void> _startSignedOut() async {
  SharedPreferences.setMockInitialValues({});
  await LocalStorage.init();
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_startSignedOut);
  tearDown(endAuthDemoSession);

  test('the 1.13.0 address list is kept', () {
    expect(demoSignInAddresses, {
      'partner@demo.rokct.ai',
      'admin@demo.rokct.ai',
      'customer@demo.rokct.ai',
      'driver@demo.rokct.ai',
      'manager@demo.rokct.ai',
      'thandi.mokoena@outlook.com',
    });
    expect(isDemoSignInAddress('  Thandi.Mokoena@Outlook.com '), isTrue);
    expect(isDemoSignInAddress('someone@outlook.com'), isFalse);
  });

  test('Thandi\'s outlook address signs in offline as Thandi (student)',
      () async {
    expect(DemoSession.demoActive, isFalse);
    expect(await beginDemoSignInIfListed('thandi.mokoena@outlook.com'),
        isTrue);
    expect(DemoSession.demoActive, isTrue);
    final user = await signInDemo('thandi.mokoena@outlook.com');
    expect(user.firstname, 'Thandi');
    expect(user.email, 'thandi.mokoena@outlook.com');
    expect(user.role, 'student');
    expect(user.isDemoAccount, isTrue);
  });

  test('customer@demo.rokct.ai signs in offline as Thandi (customer)',
      () async {
    expect(await beginDemoSignInIfListed('customer@demo.rokct.ai'), isTrue);
    expect(DemoSession.demoActive, isTrue);
    final user = await signInDemo('customer@demo.rokct.ai');
    expect(user.firstname, 'Thandi');
    expect(user.role, 'customer');
  });

  test('an unlisted address does not switch the session to demo', () async {
    expect(await beginDemoSignInIfListed('ray@example.org'), isFalse);
    expect(DemoSession.demoActive, isFalse);
  });

  test('login_notifier starts the demo session before the radio check', () {
    final src = File(
      'lib/src/common/application/auth/login/login_notifier.dart',
    ).readAsStringSync().replaceAll(RegExp(r'//[^\n]*'), '');
    final login = src.indexOf('Future<void> login(BuildContext context)');
    final demo = src.indexOf('beginDemoSignInIfListed(', login);
    final radio = src.indexOf('AppConnectivity.connectivity()', login);
    expect(demo, greaterThan(login));
    expect(demo, lessThan(radio));
  });
}
