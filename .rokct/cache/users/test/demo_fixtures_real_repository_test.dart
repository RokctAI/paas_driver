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


// Demo runs the REAL UserRepository and AddressRepository: base_sdk's
// DemoGatewayInterceptor answers every api.user.* cmd from
// templates/assets/demo/users in a demo session, the tour included.

import 'dart:io';

import 'package:base_sdk/base_sdk.dart'
    show DemoFixtureMissing, DemoFixtures, DemoSession, HttpService, LocalStorage, getIt;
import 'package:base_sdk/src/domain/interface/address.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:users_sdk/src/common/di/users_di.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/address_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/user_repository.dart';

T _ok<T>(ApiResult<T> r) =>
    r.when(success: (d) => d, failure: (e, _) => throw StateError(e));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await DemoSession.instance.activate();
    if (!getIt.isRegistered<HttpService>()) {
      getIt.registerSingleton<HttpService>(HttpService());
    }
    DemoFixtures.reset();
    DemoFixtures.loader = (key) async {
      final f = File(key.replaceFirst(
          '$usersDemoFixtureDirectory/', 'templates/assets/demo/users/'));
      return f.existsSync() ? f.readAsString() : null;
    };
    DemoFixtures.registerAssetDirectory(usersDemoFixtureDirectory);
  });

  tearDown(() async {
    DemoFixtures.reset();
    await DemoSession.instance.clear();
  });

  test('the hook registers the real repositories and the fixtures', () {
    final c = GetIt.asNewInstance();
    DemoFixtures.reset();
    UsersSdkDependencies.register(c);
    expect(c<UserRepositoryFacade>(), isA<UserRepository>());
    expect(c<AddressRepositoryFacade>(), isA<AddressRepository>());
    expect(DemoFixtures.directories, [usersDemoFixtureDirectory]);
  });

  test('each demo account reads its own profile', () async {
    final repo = UserRepository();
    DemoFixtures.role = () => 'deliveryman';
    final driver = _ok(await repo.getProfileDetails()).data!;
    expect(driver.firstname, 'Thandi');
    expect(driver.role, 'deliveryman');
    expect(driver.wallet!.price, 793.0);
    expect(driver.img, startsWith('data:image/svg+xml'));
    expect(driver.wallet!.currency!.symbol, 'R');
    expect(driver.addresses!.single.title, 'Home');
    DemoFixtures.role = () => 'partner';
    expect(_ok(await repo.getProfileDetails()).data!.firstname, 'Nomvula');
    DemoFixtures.role = () => 'admin';
    expect(_ok(await repo.getProfileDetails()).data!.id, '3');
  });

  test('account writes and the address book answer without a backend',
      () async {
    final repo = UserRepository();
    expect(_ok(await repo.getReferralDetails()).active, isFalse);
    _ok(await repo.setActiveAddress(id: '1'));
    _ok(await repo.deleteAddress(id: '2'));
    _ok(await repo.updateFirebaseToken('t'));
    expect(_ok(await repo.editProfile(user: null)).data!.lastname, 'Mokoena');
    final addresses = _ok(await AddressRepository().getUserAddresses()).data!;
    expect(addresses.map((a) => a.title), ['Home', 'Work']);
  });

  test('a cmd without a fixture fails loudly', () async {
    DemoFixtures.reset();
    await expectLater(
      DemoFixtures.answer('api.user.nope', const {}),
      throwsA(isA<DemoFixtureMissing>()),
    );
  });
}
