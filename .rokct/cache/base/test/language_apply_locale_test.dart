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


// Saving a language changes the running app. makeSelectedLang used to
// write LocalStorage only, so MaterialApp.locale and the text direction
// (read from appProvider) stayed as they were until the next cold start.

// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/application/app_widget/app_provider.dart';
import 'package:base_sdk/src/application/language/language_provider.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// Translations never load: the language must still apply (bundled copy).
class _NoTranslations extends Fake implements SettingsRepositoryFacade {
  @override
  Future<ApiResult<MobileTranslationsResponse>> getMobileTranslations() async =>
      const ApiResult.failure(error: 'unreachable', statusCode: 500);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');

  setUpAll(() {
    if (!getIt.isRegistered<SettingsRepositoryFacade>()) {
      getIt.registerSingleton<SettingsRepositoryFacade>(_NoTranslations());
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      if (call.method == 'check') return ['wifi'];
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
  });

  testWidgets('Save updates appProvider locale and direction',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        context = c;
        return const SizedBox.shrink();
      }),
    ));

    expect(container.read(appProvider).activeLanguage, isNull);
    final notifier = container.read(languageProvider.notifier);
    notifier.state = notifier.state.copyWith(
      list: [
        LanguageData(id: 'en', title: 'English', locale: 'en'),
        LanguageData(id: 'ar', title: 'Arabic', locale: 'ar', backward: true),
      ],
      index: 1,
    );

    await tester.runAsync(() => notifier.makeSelectedLang(context));

    final app = container.read(appProvider);
    expect(app.activeLanguage?.locale, 'ar');
    expect(app.isLtr, isFalse);
    expect(LocalStorage.getLanguage()?.locale, 'ar');
  });

  testWidgets('an empty list saves nothing and does not throw',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        context = c;
        return const SizedBox.shrink();
      }),
    ));
    await tester.runAsync(
      () => container.read(languageProvider.notifier).makeSelectedLang(context),
    );
    expect(container.read(appProvider).activeLanguage, isNull);
  });
}
