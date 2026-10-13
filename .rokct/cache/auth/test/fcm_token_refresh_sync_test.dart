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

// The FCM token used to reach the backend only at sign-in, so a token
// Firebase rotated later left the backend pushing to a dead one.
// FcmTokenSync re-sends each refreshed token while signed in.

import 'dart:async';

import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/src/common/services/platform_support.dart';

class _RecordingUserRepository implements UserRepositoryFacade {
  final List<String?> tokens = <String?>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #updateFirebaseToken) {
      tokens.add(invocation.positionalArguments.first as String?);
      return Future<ApiResult<void>>.value(
        const ApiResult<void>.success(data: null),
      );
    }
    throw StateError('unexpected ${invocation.memberName}');
  }
}

/// In-memory [SecureStore] so setToken never touches a platform channel.
class _MemorySecureStore implements SecureStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<String> refresh;
  late _RecordingUserRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocalStorage.init();
    SecureStorage.store = _MemorySecureStore();
    refresh = StreamController<String>();
    repo = _RecordingUserRepository();
    await FcmTokenSync.reset();
    await FcmTokenSync.start(
      repository: () => repo,
      tokenRefresh: refresh.stream,
    );
  });

  tearDown(() async {
    await FcmTokenSync.reset();
    await refresh.close();
  });

  test('a refreshed token is re-sent while signed in', () async {
    await LocalStorage.setToken('server-token');
    refresh.add('fcm-2');
    await pumpEventQueue();
    expect(repo.tokens, <String?>['fcm-2']);
  });

  test('nothing is sent while signed out', () async {
    refresh.add('fcm-2');
    await pumpEventQueue();
    expect(repo.tokens, isEmpty);
  });

  test('an offline account (no backend session) sends nothing', () async {
    await LocalStorage.setToken('offline:local-1');
    refresh.add('fcm-2');
    await pumpEventQueue();
    expect(repo.tokens, isEmpty);
  });
}
