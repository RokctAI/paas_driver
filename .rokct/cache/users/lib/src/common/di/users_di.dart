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
import 'package:base_sdk/src/domain/interface/address.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/user_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/address_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/mock_address_repository.dart';
import 'package:users_sdk/src/common/infrastructure/repositories/mock_user_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `UsersSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
///
/// The repositories follow the demo switch, [DemoSession.demoActive]: a
/// demo BUILD (`--dart-define=IS_DEMO=true`, the tour and the store
/// stills) or the runtime demo SESSION a backend-marked account flips at
/// sign-in (base_sdk 1.61.0). Both are served from the in-app fixtures;
/// every other session talks to the backend. The switch is read once at
/// registration and again on every flip: [register] subscribes once to
/// [DemoSession.instance], and the listener replaces this SDK's two
/// singletons in place - the demo twins on activate (after the real
/// backend accepted the sign-in, before routing), the real ones on clear
/// (sign-out, or a sign-in the backend answered without the marker) - so
/// a demo session's edits never reach a real profile or address book,
/// and a real session never reads the fixtures.
class UsersSdkDependencies {
  /// The container the listener re-registers into: the one the latest
  /// [register] call was given (a composed app has exactly one).
  static GetIt? _getIt;

  static void register(GetIt getIt) {
    _registerRepositories(getIt);
    _followDemoSession(getIt);
  }

  /// Registers whichever twin the switch selects right now, leaving an
  /// existing registration alone (idempotent, like every SDK hook).
  ///
  /// Without the split every profileProvider.fetchUser in a demo build
  /// went to the HTTP repository, failed, and base_sdk's
  /// GenericProfilePage fell back to "Profile" / "?" in the tour stills
  /// (auth never persists the login user; production relies on this
  /// fetch). The runtime session needs the same split for the same reason.
  static void _registerRepositories(GetIt getIt) {
    final demo = DemoSession.demoActive;
    if (!getIt.isRegistered<UserRepositoryFacade>()) {
      getIt.registerSingleton<UserRepositoryFacade>(
        demo ? MockUserRepository() : UserRepository(),
      );
    }
    if (!getIt.isRegistered<AddressRepositoryFacade>()) {
      getIt.registerSingleton<AddressRepositoryFacade>(
        demo ? MockAddressRepository() : AddressRepository(),
      );
    }
  }

  /// One listener per hook, however often [register] runs: the same
  /// static callback is removed before it is added, so a hot restart or a
  /// hand-wired host calling the hook twice never stacks subscriptions.
  static void _followDemoSession(GetIt getIt) {
    _getIt = getIt;
    DemoSession.instance
      ..removeListener(_onDemoSessionChanged)
      ..addListener(_onDemoSessionChanged);
  }

  /// [DemoSession] only notifies on an actual flip, so every call means
  /// the selected twins changed: drop this SDK's two registrations (only
  /// those, and only when present - a container reset or a flip before
  /// boot finished registering must never throw here) and register the
  /// twins the switch now selects. Callers resolve the facades per call
  /// through get_it, so the next call already lands on the new twin.
  static void _onDemoSessionChanged() {
    final getIt = _getIt;
    if (getIt == null) return;
    if (getIt.isRegistered<UserRepositoryFacade>()) {
      getIt.unregister<UserRepositoryFacade>();
    }
    if (getIt.isRegistered<AddressRepositoryFacade>()) {
      getIt.unregister<AddressRepositoryFacade>();
    }
    _registerRepositories(getIt);
  }
}
