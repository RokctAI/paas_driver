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
