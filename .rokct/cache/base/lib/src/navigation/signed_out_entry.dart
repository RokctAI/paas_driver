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


import 'package:base_sdk/src/services/local_storage.dart';

/// Where a cold start goes when nobody is signed in.
///
/// The splash used to send every signed-out start to the login page. A
/// home-screen launcher is cold-started by Android all the time (the HOME
/// intent after process death, a config change, a low-memory kill), so a
/// person who chose not to sign in was put back on the login page over and
/// over (Ray, 2026-10-10: "it's like it's forcing you to login"), and the
/// login page's Skip was remembered only for as long as the process lived.
///
/// The rule:
///
/// * A person who tapped Skip once ([rememberGuest]) lands home on every
///   later start, in any composition.
/// * A composition whose home works signed out sets [homeAfterFirstRun]
///   (launch_sdk does, in `LaunchSdkDependencies.register`). Then only the
///   first signed-out start on an install offers the login page
///   ([recordLoginOffered]); every later one lands home.
/// * Otherwise nothing changes: signed out goes to the login page.
///
/// Signing in stays reachable from the app's own UI (the launcher's account
/// glyph and its setup's sign-in step). Both flags are install-level, not
/// owner-scoped, and `LocalStorage.logout()` leaves them alone, because it
/// ends the session only.
class SignedOutEntry {
  const SignedOutEntry._();

  /// Set by a home SDK whose home works without an account.
  static bool homeAfterFirstRun = false;

  /// Whether this signed-out start should land home instead of on login.
  static bool get landsHome => landsHomeWhen(
        guestChosen: LocalStorage.getGuestEntry(),
        loginOffered: LocalStorage.getLoginOffered(),
        homeAfterFirstRun: homeAfterFirstRun,
      );

  /// The ruling itself, with its inputs handed in so it can be tested.
  static bool landsHomeWhen({
    required bool guestChosen,
    required bool loginOffered,
    required bool homeAfterFirstRun,
  }) =>
      guestChosen || (homeAfterFirstRun && loginOffered);

  /// The person chose to use the app without an account.
  static Future<void> rememberGuest() => LocalStorage.setGuestEntry(true);

  /// The splash has handed a signed-out start to the login page.
  static Future<void> recordLoginOffered() => LocalStorage.setLoginOffered(true);
}
