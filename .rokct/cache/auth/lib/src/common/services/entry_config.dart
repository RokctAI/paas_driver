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

// compliance-ignore-file: obs-flutter-trace (false positive: this file makes
// no network calls at all — it is pure composition config;
// the check fires solely because the file's path contains "services")

import 'package:flutter/widgets.dart';

/// Composition-declared entry-surface capabilities — the login twin of
/// [AuthRegistrationConfig] (registration_config.dart).
///
/// auth_sdk owns the ONE login page every composed app shows, but whether
/// that app wants a guest path past it is composition DATA (Ray's rule:
/// "let it be there in all apps, and make home sdk tell it doesnt need
/// it"). The default keeps the affordance ON, so consumer apps
/// (customer/supacharge) get guest entry with no declaration at all; an
/// app whose home surface has nothing for a guest (driver/manager) turns
/// it off through the existing manifest "integrations" channel, targeting
/// the `// @auth-entry-config` placeholder in the installed
/// auth_route_pages.dart shell (e.g. delivery_sdk's driver flavor
/// contributing `AuthEntryConfig.showsGuestSkip = false;`).
class AuthEntryConfig {
  AuthEntryConfig._();

  /// Whether the login page offers its "Skip" affordance — using the app
  /// without an account. ON by default: only a composition whose home SDK
  /// declares it has no guest surface hides it.
  static bool showsGuestSkip = true;

  /// Which welcome layout the login page draws (Ray, 2026-11-27: "let each
  /// home SDK declare what it needs and how it needs on the login page").
  /// [AuthEntryLayout.photo] is the full-bleed splash picture every app had
  /// before this switch, so an app whose home SDK declares nothing is
  /// unchanged. A home SDK picks [AuthEntryLayout.card] through the same
  /// `// @auth-entry-config` integration that sets [showsGuestSkip].
  static AuthEntryLayout layout = AuthEntryLayout.photo;

  /// Card layout: an asset path (in the host app) drawn above the title, in
  /// place of the app name in the logo font. Null keeps the app name.
  static String? heroAsset;

  /// Card layout: a widget drawn above the title, for a home SDK whose mark
  /// is drawn in code rather than a picture (Sticks: a living Stick). Wins
  /// over [heroAsset]. Set from the home SDK's own boot code (a di_hook),
  /// since the integration line cannot import the home SDK.
  static WidgetBuilder? heroBuilder;

  /// Card layout: translation key of the headline. Null shows the app name.
  static String? titleTrKey;

  /// Card layout: translation key of the line under the headline. Null
  /// draws no line.
  static String? subtitleTrKey;

  /// Card layout: translation key of a small pill above the headline
  /// (e.g. "Your AI team"). Null draws none.
  static String? badgeTrKey;

  /// Card layout: translation key of the small line above the main button
  /// (e.g. "Sign in with your Sticks account"). Null draws none.
  static String? signInLineTrKey;

  /// Card layout: translation key of the main button. Null reads "Login".
  static String? loginLabelTrKey;

  /// Card layout: the social sign-ins offered as full-width buttons above
  /// the email button, in this order (e.g. Google first, like the Claude
  /// sign-in Ray shared). Each runs the login notifier's existing
  /// loginWithGoogle / loginWithFacebook / loginWithApple. Apple shows on iOS
  /// and macOS only. Empty: email only.
  static List<AuthSocialSignIn> socialSignIns = const [];

  /// Whether the Register button is offered. ON by default; an app whose
  /// accounts are made elsewhere (Sticks: on the web) turns it off.
  static bool showsRegister = true;

  /// Puts every field back to its default. Tests only.
  @visibleForTesting
  static void reset() {
    showsGuestSkip = true;
    layout = AuthEntryLayout.photo;
    heroAsset = null;
    heroBuilder = null;
    titleTrKey = null;
    subtitleTrKey = null;
    showsRegister = true;
    badgeTrKey = null;
    signInLineTrKey = null;
    loginLabelTrKey = null;
    socialSignIns = const [];
  }
}

/// The login page's welcome layouts a home SDK can pick from.
enum AuthEntryLayout {
  /// Full-bleed splash picture with the buttons over it (the default).
  photo,

  /// A centred card on the app's own surface: picture or app name, headline,
  /// one line, then the Login (and Register) buttons. Follows light and
  /// dark mode.
  card,
}

/// Social sign-ins a home SDK can put on the card login.
enum AuthSocialSignIn { google, facebook, apple }
