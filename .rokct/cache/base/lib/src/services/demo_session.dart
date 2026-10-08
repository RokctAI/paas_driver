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


import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// The fleet's demo switch.
///
/// A real account on the production backend, one per role, signs in through
/// the real `AuthRepository` like anyone else; when the backend's login
/// payload marks that account (`is_demo_account`,
/// [UserModel.isDemoAccount]) the login flow calls [activate] and the app
/// serves that session from the in-app fixtures ("demo login in
/// production", Ray, 2026-09-08). Nothing on screen says demo - the account
/// is a real person to the user, the backend is the only gatekeeper, and
/// knowing the address grants nothing without its real password.
///
/// The guided tour, the render strip and the store screenshots run the one
/// build that has no backend and no sign-in to assert a marker with, so
/// they keep their fixtures through [AppConstants.isTour]
/// (`--dart-define=TOUR_MODE=true`). There is no other build flag: the
/// former `AppConstants.isDemo` (`--dart-define=IS_DEMO=true`) is gone.
///
/// Session-scoped: [active] is persisted in [LocalStorage] under
/// `demo_session_active`, so a relaunch that restores the stored token
/// restores the demo session with it, and it is cleared by [clear] - which
/// [LocalStorage.logout] calls on every sign-out path (users_sdk's
/// logout / delete-account, the 401 auto-logout) - and by any sign-in the
/// backend answers WITHOUT the marker, so a demo session can never leak
/// into a real account.
///
/// [demoActive] is the one question every demo seam asks: the per-SDK DI
/// ternaries read it at registration and re-register on [addListener], so
/// a marked account signing in after boot is served the fixtures and a
/// sign-out ending its session gets the real repositories back.
class DemoSession extends ChangeNotifier {
  DemoSession._();

  /// The app-wide session. A single instance, like the storage it fronts.
  static final DemoSession instance = DemoSession._();

  /// True while a server-marked demo account is signed in. Reads the
  /// persisted flag on every call (SharedPreferences answers from its
  /// in-memory cache, so this is a map lookup) rather than caching it, so
  /// a read that lands before [LocalStorage.init] can never pin a stale
  /// `false` for the rest of the process. False until [activate], and
  /// again after [clear] or a sign-out.
  bool get active => LocalStorage.getDemoSessionActive();

  /// Whether the app should serve the in-app fixtures right now, and the
  /// only demo switch the fleet has.
  ///
  /// Two sources, and no build flag beyond the first. The guided-tour build
  /// (`--dart-define=TOUR_MODE=true`) runs with no backend and no sign-in,
  /// so it keeps its in-app fixtures through [AppConstants.isTour];
  /// everything else is the runtime session ([active]), which auth_sdk
  /// activates from the server-asserted demo-account marker on the login
  /// payload. A shipped build sets no define, so there it is the session
  /// alone.
  static bool get demoActive => AppConstants.isTour || instance.active;

  /// Switches the running session to demo. Called by the login flow
  /// strictly AFTER the real backend has accepted the credentials and its
  /// payload carries the marker - never from a typed address or a
  /// password. Persists first (the preference cache updates synchronously,
  /// so [active] already answers true to the listeners), then notifies.
  /// No-op, and no notification, when the session is already demo.
  Future<void> activate() async {
    if (active) return;
    await LocalStorage.setDemoSessionActive(true);
    notifyListeners();
  }

  /// Ends the demo session: drops the persisted flag and notifies. Called
  /// from [LocalStorage.logout] on every sign-out, and by the login flow
  /// when a sign-in comes back without the marker. No-op, and no
  /// notification, when the session is not demo.
  Future<void> clear() async {
    if (!active) return;
    await LocalStorage.deleteDemoSessionActive();
    notifyListeners();
  }
}
