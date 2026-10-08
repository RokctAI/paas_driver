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

// Ray registered as sinyage@gmail.com and saw none of his seeded tasks:
// productivity's MaintenanceSeed reads LocalStorage.getUser()?.email, and
// only login stored the profile - register and confirmation stored the
// token alone. Every sign-up path now stores the profile the way login
// does, fetching it when the response carries no user.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart' show LocalStorage;
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/src/common/services/session_profile.dart';

class _Users implements UserRepositoryFacade {
  int fetches = 0;
  @override
  Future<ApiResult<ProfileResponse>> getProfileDetails() async {
    fetches++;
    return ApiResult.success(
      data: ProfileResponse(
        data: ProfileData(id: '7', email: 'sinyage@gmail.com'),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  test('a registration that returns the user stores it', () async {
    final users = _Users();
    await storeSessionProfile(
      UserModel(id: '7', email: 'sinyage@gmail.com'),
      users,
    );
    expect(LocalStorage.getUser()?.email, 'sinyage@gmail.com');
    expect(users.fetches, 0);
  });

  test('a registration without a user fetches and stores the profile',
      () async {
    final users = _Users();
    await storeSessionProfile(null, users);
    expect(LocalStorage.getUser()?.email, 'sinyage@gmail.com');
    expect(users.fetches, 1);
  });

  test('every register and confirmation token store also stores the user',
      () {
    for (final path in [
      'lib/src/common/application/auth/register/register_notifier.dart',
      'lib/src/common/application/auth/confirmation/'
          'register_confirmation_notifier.dart',
    ]) {
      final src = File(path).readAsStringSync();
      final tokens = 'LocalStorage.setToken('.allMatches(src).length;
      final profiles = 'storeSessionProfile('.allMatches(src).length;
      expect(profiles, tokens, reason: path);
    }
  });
}
