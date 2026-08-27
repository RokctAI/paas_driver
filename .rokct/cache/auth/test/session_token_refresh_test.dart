// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/handlers/token_refresh_service.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';

import 'package:auth_sdk/src/common/domain/interface/session_token_refresh.dart';
import 'package:auth_sdk/src/common/infrastructure/repositories/auth_repository.dart';

/// In-memory [SecureStore] so tests never touch platform channels.
class MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    SecureStorage.store = MemorySecureStore();
    TokenRefreshService.resetForTesting();
  });

  tearDown(TokenRefreshService.resetForTesting);

  test('AuthRepository exposes the SessionTokenRefresh capability', () {
    final AuthRepositoryFacade repository = AuthRepository();
    // The capability is reached by downcast, like DeferredOtpEmailResend:
    // callers holding only the base_sdk facade probe with `is`.
    expect(repository, isA<SessionTokenRefresh>());
  });

  test(
      'refreshSession delegates to the single-flight service '
      '(no stored refresh token -> false + cleared session)', () async {
    await LocalStorage.setToken('orphan:token');
    var expired = 0;
    TokenRefreshService.onSessionExpired = () => expired++;

    final SessionTokenRefresh capability = AuthRepository();
    expect(await capability.refreshSession(), isFalse);
    // The service treats a missing refresh token as an unrecoverable
    // session: credentials cleared, forced-re-login hook fired.
    expect(LocalStorage.getToken(), isEmpty);
    expect(expired, 1);
  });
}
