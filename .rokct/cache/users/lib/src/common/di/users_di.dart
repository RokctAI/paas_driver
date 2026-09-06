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
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/domain/interface/address.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/user_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/address_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/mock_address_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/mock_user_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `UsersSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
class UsersSdkDependencies {
  static void register(GetIt getIt) {
    // Demo builds talk to no backend: without this split every
    // profileProvider.fetchUser went to the HTTP repository, failed, and
    // base_sdk's GenericProfilePage fell back to "Profile" / "?" in the
    // tour stills (auth never persists the login user; production relies on
    // this fetch).
    if (!getIt.isRegistered<UserRepositoryFacade>()) {
      getIt.registerSingleton<UserRepositoryFacade>(
        AppConstants.isDemo ? MockUserRepository() : UserRepository(),
      );
    }
    if (!getIt.isRegistered<AddressRepositoryFacade>()) {
      getIt.registerSingleton<AddressRepositoryFacade>(
        AppConstants.isDemo ? MockAddressRepository() : AddressRepository(),
      );
    }
  }
}
