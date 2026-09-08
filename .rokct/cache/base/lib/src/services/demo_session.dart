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

/// The RUNTIME half of the fleet's demo switch.
///
/// [AppConstants.isDemo] (`--dart-define=IS_DEMO=true`) is a compile-time
/// constant: the guided tour, the render strip and the store screenshots
/// build the whole app against the in-app fixtures, and a release build
/// tree-shakes every `Mock*` / `Demo*` twin out. That stays exactly as it
/// is. This class adds the second source the production build needs for
/// "demo login in production" (Ray, 2026-09-08): a real account on the
/// production backend, one per role, signs in through the real
/// `AuthRepository` like anyone else; when the backend's login payload
/// marks that account (`is_demo_account`, [UserModel.isDemoAccount]) the
/// login flow calls [activate] and the app serves that session from the
/// same fixtures the tour uses. Nothing on screen says demo - the account
/// is a real person to the user, the backend is the only gatekeeper, and
/// knowing the address grants nothing without its real password.
///
/// Session-scoped: [active] is persisted in [LocalStorage] under
/// `demo_session_active`, so a relaunch that restores the stored token
/// restores the demo session with it, and it is cleared by [clear] - which
/// [LocalStorage.logout] calls on every sign-out path (users_sdk's
/// logout / delete-account, the 401 auto-logout) - and by any sign-in the
/// backend answers WITHOUT the marker, so a demo session can never leak
/// into a real account.
///
/// [demoActive] is the one question every demo seam should ask from here
/// on: `isDemo || DemoSession.instance.active`. Phase 1 (this class) ships
/// the switch only; the per-SDK DI ternaries that today read
/// [AppConstants.isDemo] at registration are re-pointed at [demoActive]
/// in phase 2, together with a re-registration on [addListener]. Until
/// then [activate] changes nothing a user can see beyond the flag itself.
class DemoSession extends ChangeNotifier {
  DemoSession._();

  /// The app-wide session. A single instance, like the storage it fronts.
  static final DemoSession instance = DemoSession._();

  /// Test-only stand-in for [AppConstants.isDemo], which is a compile-time
  /// constant and so cannot be flipped by a test. `null` (the default)
  /// reads the constant. Same seam `DemoCurrency` and `ProfileMetaRow`
  /// carry.
  @visibleForTesting
  static bool? isDemoOverride;

  static bool get _isDemoBuild => isDemoOverride ?? AppConstants.isDemo;

  /// True while a server-marked demo account is signed in. Reads the
  /// persisted flag on every call (SharedPreferences answers from its
  /// in-memory cache, so this is a map lookup) rather than caching it, so
  /// a read that lands before [LocalStorage.init] can never pin a stale
  /// `false` for the rest of the process. False until [activate], and
  /// again after [clear] or a sign-out.
  bool get active => LocalStorage.getDemoSessionActive();

  /// Whether the app should serve the in-app fixtures right now: a demo
  /// BUILD ([AppConstants.isDemo]) or a demo SESSION ([active]).
  static bool get demoActive => _isDemoBuild || instance.active;

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
