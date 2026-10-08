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

import 'package:get_it/get_it.dart';
import 'package:base_sdk/base_sdk.dart' show DemoFixtures;
import 'package:base_sdk/src/domain/interface/address.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/user_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/address_repository.dart';

/// Host asset directory holding users_sdk's demo platform fixtures
/// (`<cmd>.json`), installed from `templates/assets/demo/users`.
const String usersDemoFixtureDirectory = 'assets/demo/users';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `UsersSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
///
/// Demo (the guided tour or a server-marked demo account's session) runs
/// the REAL repositories: base_sdk's DemoGatewayInterceptor answers every
/// `api.user.*` cmd from the `<cmd>.json` fixtures in
/// [usersDemoFixtureDirectory] while DemoSession.demoActive, read per
/// request, so no re-registration on a session flip is needed and a
/// missing fixture fails loudly (DemoFixtureMissing). The profile answer is
/// picked by the signed-in account's role (each demo account has its own).
class UsersSdkDependencies {
  static void register(GetIt getIt) {
    DemoFixtures.registerAssetDirectory(usersDemoFixtureDirectory);
    if (!getIt.isRegistered<UserRepositoryFacade>()) {
      getIt.registerSingleton<UserRepositoryFacade>(UserRepository());
    }
    if (!getIt.isRegistered<AddressRepositoryFacade>()) {
      getIt.registerSingleton<AddressRepositoryFacade>(AddressRepository());
    }
  }
}
