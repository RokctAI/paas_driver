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

// DevicePushToken.forLogout is the ONE read of this device's push token for
// a sign-out, shared by ProfileNotifier.logOut and launch_sdk's
// LauncherAuthControl.logOut, so the backend can delete the Device Token
// row. It never throws and never holds a sign-out: offline, without
// Firebase, or past its timeout the answer is ''.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/application/profile/profile_notifier.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/device_push_token.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';

class _MemorySecureStore implements SecureStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _RecordingUserRepository extends Fake implements UserRepositoryFacade {
  final List<String> fcms = <String>[];

  @override
  Future<ApiResult<dynamic>> logoutAccount({required String fcm}) async {
    fcms.add(fcm);
    return const ApiResult<dynamic>.success(data: null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => DevicePushToken.readOverride = null);

  group('DevicePushToken.forLogout', () {
    test('answers the token', () async {
      DevicePushToken.readOverride = () async => 'fcm-1';
      expect(await DevicePushToken.forLogout(), 'fcm-1');
    });

    test('a null token is empty', () async {
      DevicePushToken.readOverride = () async => null;
      expect(await DevicePushToken.forLogout(), '');
    });

    test('offline (the read throws) is empty, not an error', () async {
      DevicePushToken.readOverride =
          () async => throw Exception('SERVICE_NOT_AVAILABLE');
      expect(await DevicePushToken.forLogout(), '');
    });

    test('a read that never answers gives up after the timeout', () async {
      DevicePushToken.readOverride = () => Completer<String?>().future;
      final Stopwatch watch = Stopwatch()..start();
      expect(await DevicePushToken.forLogout(), '');
      expect(watch.elapsed, lessThan(DevicePushToken.timeout * 2));
    });

    test('no Firebase app at all is empty, not an error', () async {
      // No override: the real FirebaseMessaging read, with no Firebase app
      // initialised under the test binding, throws [core/no-app].
      expect(await DevicePushToken.forLogout(), '');
    });
  });

  test('ProfileNotifier.logOut sends the token with the logout', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
    SecureStorage.store = _MemorySecureStore();
    DevicePushToken.readOverride = () async => 'fcm-2';
    final _RecordingUserRepository repository = _RecordingUserRepository();

    await ProfileNotifier(repository, null, null).logOut();

    expect(repository.fcms, <String>['fcm-2']);
  });
}
