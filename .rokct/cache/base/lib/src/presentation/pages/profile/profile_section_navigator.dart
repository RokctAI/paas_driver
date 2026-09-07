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

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';

/// Host seam for a profile section's card: on planes, open the section's
/// detail in the profile host's DETAIL PLANE instead of pushing a
/// full-screen route (Ray 2026-09-07).
///
/// A profile host that hosts [GenericProfilePage] on a [PlaneHost]
/// provides this scope above the page with an [onOpen] that pushes the
/// section's [ProfileSection.detailBuilder] onto its plane stack — the
/// routed `/generic-profile` page ([GenericProfileRoutePage]) does so at
/// plane widths. A section card calls [open] from its tap and keeps its
/// ordinary push as the fallback:
///
/// ```dart
/// onTap: () {
///   if (ProfileSectionNavigator.open(context, 'lms.student.subjects')) return;
///   context.router.push(CourseCatalogRoute()); // the phone, as before
/// }
/// ```
///
/// [open] answers false — the card should push exactly as it always did —
/// whenever there is no host scope above [context], the page is not on
/// planes (a phone route), or the section declares no `detailBuilder`. So
/// a card that adopts the seam is byte-identical on phones by construction.
class ProfileSectionNavigator extends InheritedWidget {
  /// Pushes [section]'s detail onto the host's plane stack (the last
  /// plane). Never null: a host that cannot open details provides no
  /// scope at all.
  final void Function(ProfileSection section) onOpen;

  /// The section whose detail the host shows right now, or null while the
  /// detail plane is empty. Inherited, so a card may highlight itself.
  final String? openSectionId;

  const ProfileSectionNavigator({
    super.key,
    required this.onOpen,
    required this.openSectionId,
    required super.child,
  });

  /// The enclosing host's seam, or null outside a plane-hosting profile.
  static ProfileSectionNavigator? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileSectionNavigator>();

  /// Opens the registered section [sectionId]'s detail in the host's
  /// detail plane. True when it did; false when the card should fall back
  /// to its own push (no host scope, not on planes, no detail, or no such
  /// section). Safe to call from a tap handler.
  static bool open(BuildContext context, String sectionId) {
    final section = ProfileSectionRegistry.I.section(sectionId);
    if (section?.detailBuilder == null) return false;
    if (context.getInheritedWidgetOfExactType<Planes>() == null) return false;
    final host =
        context.getInheritedWidgetOfExactType<ProfileSectionNavigator>();
    if (host == null) return false;
    host.onOpen(section!);
    return true;
  }

  @override
  bool updateShouldNotify(ProfileSectionNavigator oldWidget) =>
      openSectionId != oldWidget.openSectionId || onOpen != oldWidget.onOpen;
}
