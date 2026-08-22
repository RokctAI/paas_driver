// Copyright (c) 2026 RokctAI
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


import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value contract behind [SecureStorage], so tests (and any
/// platform without a flutter_secure_storage backend) can swap the store
/// for an in-memory one without touching platform channels.
abstract class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class _FlutterSecureStore implements SecureStore {
  const _FlutterSecureStore();

  // encryptedSharedPreferences avoids the Android keystore/RSA legacy path
  // and its known lockscreen-change data-loss issues.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Secure (keystore/keychain-backed) storage for long-lived credentials.
///
/// The access token intentionally stays in [SharedPreferences] via
/// LocalStorage — it is short-lived (24h) and widely read synchronously.
/// The refresh token is the long-lived credential that can mint new access
/// tokens, so it lives here instead of plaintext prefs.
abstract class SecureStorage {
  SecureStorage._();

  static const String keyRefreshToken = 'keyRefreshToken';

  static SecureStore _store = const _FlutterSecureStore();

  /// Test seam: swap the backing store (in-memory in unit tests, where
  /// platform channels are unavailable).
  @visibleForTesting
  static set store(SecureStore store) => _store = store;

  static Future<String> getRefreshToken() async =>
      (await _store.read(keyRefreshToken)) ?? '';

  /// Persist [token]; null/empty deletes the stored value.
  static Future<void> setRefreshToken(String? token) =>
      (token == null || token.isEmpty)
          ? _store.delete(keyRefreshToken)
          : _store.write(keyRefreshToken, token);

  static Future<void> deleteRefreshToken() => _store.delete(keyRefreshToken);
}
