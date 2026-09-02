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

import 'package:flutter/widgets.dart';

import 'package:base_sdk/src/navigation/embedded_widgets.dart';

/// The cross-SDK widgets the login screen borrows through
/// [EmbeddedWidgets], each resolved ONCE and each optional.
///
/// A registry method is only real when an installed SDK declares it in its
/// manifest's "embedded_widgets" list. On a host that does not compose the
/// owning SDK, the generated `_HostEmbeddedWidgets` has no override for it
/// and its `noSuchMethod` throws a [StateError]. The login screen is
/// reachable in compositions that own none of these SDKs (a launcher
/// composing only base + users + auth + launch, for instance), so calling
/// them unguarded threw instead of rendering the screen.
///
/// This is the same guard the intro page has carried since it hit the same
/// wall — see [LoginEmbeddedSlots.resolve] — lifted to one place so every
/// borrowed widget is resolved once, off the build path, and a missing SDK
/// becomes `null` (hide the affordance) rather than a crash.
///
/// Nothing here changes a composed app: when the owning SDK IS installed
/// every slot resolves to exactly the widget the registry returned before.
@immutable
class LoginEmbeddedSlots {
  const LoginEmbeddedSlots({
    this.introPage,
    this.languageScreen,
    this.termPage,
    this.policyPage,
  });

  /// Onboarding carousel behind "Skip" — null when no onboarding SDK is
  /// composed (e.g. manager/driver), which hides the Skip fall-through.
  final Widget? introPage;

  /// comms_sdk's language picker, already wired to its `onSave`. Null when
  /// comms_sdk is absent: such an app has no language surface anywhere, so
  /// the picker is simply never offered.
  final Widget? languageScreen;

  /// corporate_sdk's terms page, pushed from the legal line.
  final Widget? termPage;

  /// corporate_sdk's privacy-policy page, pushed from the legal line.
  final Widget? policyPage;

  /// Whether the sign-up legal line can be rendered.
  ///
  /// Both pages are declared by corporate_sdk, so in practice they arrive
  /// and vanish together; requiring both keeps the sentence whole either
  /// way, since it reads "...you have read and accepted the Terms & Privacy
  /// Policy" and has no meaning with a link missing from its tail.
  bool get hasLegalPages => termPage != null && policyPage != null;

  /// Resolves every slot against the registry the host installed.
  ///
  /// [onLanguageSaved] is handed to comms_sdk's picker as its `onSave`; it
  /// is captured once here rather than per-open, which is the same callback
  /// the caller passed before.
  static LoginEmbeddedSlots resolve({
    required VoidCallback onLanguageSaved,
  }) {
    return LoginEmbeddedSlots(
      introPage: _slot('introPage', () => EmbeddedWidgets.I.introPage()),
      languageScreen: _slot(
        'languageScreen',
        () => EmbeddedWidgets.I.languageScreen(onSave: onLanguageSaved),
      ),
      termPage: _slot('termPage', () => EmbeddedWidgets.I.termPage()),
      policyPage: _slot('policyPage', () => EmbeddedWidgets.I.policyPage()),
    );
  }

  /// One registry lookup, guarded exactly as the intro page's was: only
  /// [StateError] — the registry's own "not composed" signal — is absorbed,
  /// so a real failure inside a composed SDK's widget still surfaces.
  static Widget? _slot(String name, Widget Function() lookup) {
    try {
      return lookup();
    } on StateError catch (e) {
      debugPrint(
        '==> LoginPage: no $name composed, hiding that affordance: $e',
      );
      return null;
    }
  }
}
