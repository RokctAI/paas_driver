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


import 'package:base_sdk/src/navigation/signed_out_entry.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';
import 'package:base_sdk/src/services/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemorySecureStore implements SecureStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> boot(Map<String, Object> prefs) async {
    SecureStorage.store = _MemorySecureStore();
    SharedPreferences.setMockInitialValues(prefs);
    await LocalStorage.init();
  }

  tearDown(() => SignedOutEntry.homeAfterFirstRun = false);

  group('SignedOutEntry.landsHomeWhen', () {
    test('a fresh install goes to login', () {
      expect(
        SignedOutEntry.landsHomeWhen(
            guestChosen: false, loginOffered: false, homeAfterFirstRun: true),
        isFalse,
      );
    });

    test('a remembered Skip lands home in any composition', () {
      expect(
        SignedOutEntry.landsHomeWhen(
            guestChosen: true, loginOffered: false, homeAfterFirstRun: false),
        isTrue,
      );
    });

    test('after the first run, a signed-out-home composition lands home', () {
      expect(
        SignedOutEntry.landsHomeWhen(
            guestChosen: false, loginOffered: true, homeAfterFirstRun: true),
        isTrue,
      );
    });

    test('other compositions keep the login page after the first run', () {
      expect(
        SignedOutEntry.landsHomeWhen(
            guestChosen: false, loginOffered: true, homeAfterFirstRun: false),
        isFalse,
      );
    });
  });

  group('persistence', () {
    test('the launcher offers login once, then lands home on restart',
        () async {
      await boot({});
      SignedOutEntry.homeAfterFirstRun = true;
      expect(SignedOutEntry.landsHome, isFalse);
      await SignedOutEntry.recordLoginOffered();

      // A cold start reads the same preferences back.
      await boot({StorageKeys.keyLoginOffered: true});
      expect(SignedOutEntry.landsHome, isTrue);
    });

    test('Skip survives a restart and a logout', () async {
      await boot({});
      await SignedOutEntry.rememberGuest();
      LocalStorage.logout();
      expect(LocalStorage.getGuestEntry(), isTrue);
      expect(SignedOutEntry.landsHome, isTrue);

      await boot({StorageKeys.keyIsGuest: true});
      expect(SignedOutEntry.landsHome, isTrue);
    });
  });
}
