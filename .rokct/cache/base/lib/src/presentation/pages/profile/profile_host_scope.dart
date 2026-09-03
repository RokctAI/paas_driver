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

import 'package:base_sdk/src/application/profile/profile_host_capabilities.dart';

/// Hands the generic profile host's resolved [ProfileHostCapabilities] to
/// every widget it builds — registered sections, header-slot content, the
/// footer — through the build context, so a contributed widget can leave
/// out a piece that needs an absent facade without consulting GetIt
/// itself. base_sdk's own [ProfileMetaRow] reads it to drop the usage badge
/// in anonymous mode.
///
/// Read it from the WIDGET's own build context (the one Flutter passes to
/// its `build`), which sits below the host's scope; the context a section
/// `builder` receives belongs to the page element above the scope.
class ProfileHostScope extends InheritedWidget {
  /// What the host resolved when it mounted.
  final ProfileHostCapabilities capabilities;

  const ProfileHostScope({
    super.key,
    required this.capabilities,
    required super.child,
  });

  /// The enclosing host's capabilities, or null outside the generic
  /// profile host.
  static ProfileHostCapabilities? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ProfileHostScope>()
      ?.capabilities;

  /// The enclosing host's capabilities, defaulting to
  /// [ProfileHostCapabilities.all] outside the generic profile host — a
  /// widget reused on another screen renders exactly as it always did.
  static ProfileHostCapabilities of(BuildContext context) =>
      maybeOf(context) ?? ProfileHostCapabilities.all;

  @override
  bool updateShouldNotify(ProfileHostScope oldWidget) =>
      capabilities != oldWidget.capabilities;
}
