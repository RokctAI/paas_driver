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

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the password the user typed for an offline-registered account until
/// that account syncs to the backend. The backend account must be created
/// with this password, or the user cannot sign in online with the password
/// they chose. The value lives in the OS keystore (Keychain / Keystore) via
/// flutter_secure_storage, never in the drift table or SharedPreferences.
///
/// Entries are removed as soon as the sync succeeds, or when the local
/// account is discarded. An account whose sync never happens keeps its entry
/// until it is discarded.
class OfflinePasswordVault {
  OfflinePasswordVault({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Shared instance used by OfflineAuthService.
  static final OfflinePasswordVault instance = OfflinePasswordVault();

  static const String _keyPrefix = 'offline_pending_password:';

  final FlutterSecureStorage _storage;

  String _key(String localUserId) => '$_keyPrefix$localUserId';

  Future<void> save(String localUserId, String password) =>
      _storage.write(key: _key(localUserId), value: password);

  Future<String?> read(String localUserId) =>
      _storage.read(key: _key(localUserId));

  Future<void> delete(String localUserId) =>
      _storage.delete(key: _key(localUserId));
}
