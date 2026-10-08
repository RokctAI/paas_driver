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


// Demo runs the REAL SettingsRepository: base_sdk's DemoGatewayInterceptor
// answers every platform cmd it sends from templates/assets/demo/comms.
// These tests drive the real repository through the real HttpService Dio
// stack in a demo session and check it parses every fixture it calls.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart'
    show DemoFixtures, DemoSession, HttpService, LocalStorage, getIt;
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/notification_list_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:comms_sdk/src/common/di/comms_di.dart';
import 'package:comms_sdk/src/common/infrastructure/repositories/settings_repository.dart';

T ok<T>(ApiResult<T> r) => switch (r) {
      Success<T>(:final data) => data,
      Failure<T>(:final error) => throw StateError(error),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final SettingsRepository repo = SettingsRepository();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await DemoSession.instance.activate();
    if (!getIt.isRegistered<HttpService>()) {
      getIt.registerSingleton<HttpService>(HttpService());
    }
    DemoFixtures.reset();
    // The host installs templates/assets/demo/comms at assets/demo/comms.
    DemoFixtures.loader = (key) async {
      final f = File(key.replaceFirst(
          '$commsDemoFixtureDirectory/', 'templates/assets/demo/comms/'));
      return f.existsSync() ? f.readAsString() : null;
    };
    DemoFixtures.registerAssetDirectory(commsDemoFixtureDirectory);
  });

  tearDown(() async {
    DemoFixtures.reset();
    await DemoSession.instance.clear();
  });

  test('settings, languages and translations parse from fixtures', () async {
    final settings = ok(await repo.getGlobalSettings());
    expect(settings.data!.map((e) => e.key), contains('default_currency'));
    // No 'title' fixture: AppHelpers.getAppName falls back to the composed
    // app's own AppConstants.appTitle, as the old demo twin served.
    expect(settings.data!.map((e) => e.key), isNot(contains('title')));
    final languages = ok(await repo.getLanguages());
    expect(languages.data!.single.locale, 'en');
    expect(languages.data!.single.isDefault, isTrue);
    final tr = ok(await repo.getMobileTranslations());
    expect(tr.data!['home'], 'Home');
  });

  test('faq, term, policy and notifications parse from fixtures', () async {
    final faq = ok(await repo.getFaq());
    expect(faq.data!.single.translation!.question, 'How to order?');
    expect(ok(await repo.getTerm()).title, 'Terms of Service');
    expect(ok(await repo.getPolicy()).title, 'Privacy Policy');
    final list = ok(await repo.getNotificationList());
    expect(list.data!.single.type, 'order');
    ok(await repo.updateNotification(
        [NotificationData(type: 'order', active: true)]));
  });
}
