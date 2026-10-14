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


// Splash routing vs. the global-settings fetch. A start with settings
// already stored routes at once and refreshes them in the background; only
// the first start, with nothing stored, waits for them. It used to be the
// other way round: every later start waited on the network first.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/application/splash/splash_notifier.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/response/global_settings_response.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// getGlobalSettings answers only when the test completes [gate].
class _GatedSettings extends Fake implements SettingsRepositoryFacade {
  final Completer<void> gate = Completer<void>();
  int calls = 0;

  @override
  Future<ApiResult<GlobalSettingsResponse>> getGlobalSettings() async {
    calls++;
    await gate.future;
    return ApiResult.success(data: GlobalSettingsResponse(data: const []));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivityChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');

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

  // getToken takes a context but routes only through the callbacks.
  final BuildContext context = _Context();

  test('a later start routes before the settings refresh answers', () async {
    await LocalStorage.setSettingsFetched(true);
    final settings = _GatedSettings();
    final reached = <String>[];

    await SplashNotifier(settings).getToken(
      context,
      goLogin: () => reached.add('login'),
      goMain: () => reached.add('main'),
    );
    // Routed while the refresh is still waiting on the network.
    expect(reached, ['login']);
    expect(settings.calls, 1);
    settings.gate.complete();
  });

  test('the first start waits for settings before routing', () async {
    await LocalStorage.setSettingsFetched(false);
    final settings = _GatedSettings();
    final reached = <String>[];

    final done = SplashNotifier(settings).getToken(
      context,
      goLogin: () => reached.add('login'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final before = List<String>.of(reached);
    settings.gate.complete();
    await done;
    expect(before, isEmpty);
    expect(reached, ['login']);
    expect(LocalStorage.getSettingsFetched(), isTrue);
  });
}

class _Context extends Fake implements BuildContext {}
