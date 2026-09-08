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
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:merchants_sdk/src/common/infrastructure/repositories/shops_repository.dart';
import 'package:merchants_sdk/src/common/infrastructure/repositories/mock_shops_repository.dart';

/// Installer-convention DI hook: the composed app's generated `main.dart`
/// calls `MerchantsSdkDependencies.register(GetIt.instance)` for every
/// installed SDK. Registers this SDK's repositories against their base_sdk
/// facades (idempotently, so hand-wired hosts can call it too).
///
/// The shops demo twin follows the RUNTIME demo switch, base_sdk's
/// [DemoSession.demoActive] (a demo build OR a demo session): chosen by
/// that read at registration, and swapped by the one listener this hook
/// adds to [DemoSession.instance] when the switch flips - after a demo
/// account's login, before routing, and back on sign-out. Only a
/// registration this hook made is ever swapped; a facade a host
/// registered itself is left alone.
class MerchantsSdkDependencies {
  /// The container the last [register] call wired; the listener re-wires
  /// the same one. Null until the first call, so a flip that lands before
  /// any registration is a no-op and the registration then reads the
  /// switch itself.
  static GetIt? _container;

  /// Guards the listener against being added twice.
  static bool _listening = false;

  /// The instances this hook registered (weak), so a flip replaces exactly
  /// those and never a host's own registration.
  static final Expando<bool> _ours = Expando<bool>();

  static void register(GetIt getIt) {
    _container = getIt;
    _registerDemoTwins(getIt, replace: false);
    if (!_listening) {
      _listening = true;
      DemoSession.instance.addListener(_onDemoSessionChanged);
    }
  }

  /// `replace` is false at boot (an existing registration wins, as before)
  /// and true on a flip. Nothing here can throw: unregister runs only
  /// behind `isRegistered`, and a fresh registration never collides.
  static void _registerDemoTwins(GetIt getIt, {required bool replace}) {
    final bool demo = DemoSession.demoActive;
    _put<ShopsRepositoryFacade>(
      getIt,
      () => demo ? MockShopsRepository() : ShopsRepository(),
      replace: replace,
    );
  }

  static void _put<T extends Object>(
    GetIt getIt,
    T Function() build, {
    required bool replace,
  }) {
    if (getIt.isRegistered<T>()) {
      if (!replace || _ours[getIt<T>()] != true) return;
      getIt.unregister<T>();
    }
    final T instance = build();
    _ours[instance] = true;
    getIt.registerSingleton<T>(instance);
  }

  static void _onDemoSessionChanged() {
    final GetIt? getIt = _container;
    if (getIt == null) return;
    _registerDemoTwins(getIt, replace: true);
  }
}
