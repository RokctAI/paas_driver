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
///
/// A DETAIL WITHOUT A HUB CARD (Ray 2026-09-08, the sheet fork ruling:
/// "sheet = PHONE, plane widths get a pane") goes through [openDetail]
/// with an ad-hoc builder, or — for the profile's own edit form —
/// [openEditProfile], which opens the registry's
/// [ProfileSectionRegistry.editProfileDetailBuilder]. The same false
/// answers apply, so the caller keeps its sheet as the phone fallback:
///
/// ```dart
/// onTap: () {
///   if (ProfileSectionNavigator.openEditProfile(context)) return;
///   AppHelpers.showCustomModalBottomSheet(...); // the phone, as before
/// }
/// ```
///
/// An embedded detail that is done (a form saved) leaves the pane with
/// [close]: the host pops it back to its landing state — the default
/// section's detail on three planes, the bare stage on two — without
/// popping the profile route. False outside a host, so a widget shared
/// with a sheet or a pushed route keeps its `pop` as the fallback.
class ProfileSectionNavigator extends InheritedWidget {
  /// Pushes [section]'s detail onto the host's plane stack (the last
  /// plane). Never null: a host that cannot open details provides no
  /// scope at all.
  final void Function(ProfileSection section) onOpen;

  /// Pops the open detail back to the host's landing state (see [close]).
  /// Null (the default) means the host offers no close of its own —
  /// [close] answers false there and the detail keeps its fallback.
  final VoidCallback? onClose;

  /// The section whose detail the host shows right now, or null while the
  /// detail plane is empty. Inherited, so a card may highlight itself.
  final String? openSectionId;

  const ProfileSectionNavigator({
    super.key,
    required this.onOpen,
    required this.openSectionId,
    required super.child,
    this.onClose,
  });

  /// The enclosing host's seam, or null outside a plane-hosting profile.
  static ProfileSectionNavigator? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileSectionNavigator>();

  /// The host seam able to open a detail from [context]: on planes, under
  /// a host scope. Null — the caller falls back — otherwise.
  static ProfileSectionNavigator? _hostOf(BuildContext context) {
    if (context.getInheritedWidgetOfExactType<Planes>() == null) return null;
    return context.getInheritedWidgetOfExactType<ProfileSectionNavigator>();
  }

  /// Opens the registered section [sectionId]'s detail in the host's
  /// detail plane. True when it did; false when the card should fall back
  /// to its own push (no host scope, not on planes, no detail, or no such
  /// section). Safe to call from a tap handler.
  static bool open(BuildContext context, String sectionId) {
    final section = ProfileSectionRegistry.I.section(sectionId);
    if (section?.detailBuilder == null) return false;
    final host = _hostOf(context);
    if (host == null) return false;
    host.onOpen(section!);
    return true;
  }

  /// Opens an ad-hoc detail — one with no registered section, no hub card
  /// — in the host's detail plane under the step identity [id]. True when
  /// it did; false when the caller should fall back to its own surface (a
  /// sheet, a push): no host scope or not on planes. Safe to call from a
  /// tap handler.
  static bool openDetail(
    BuildContext context, {
    required String id,
    required WidgetBuilder detailBuilder,
  }) {
    final host = _hostOf(context);
    if (host == null) return false;
    host.onOpen(ProfileSection.detailOnly(id: id, detailBuilder: detailBuilder));
    return true;
  }

  /// Whether [openEditProfile] would open a detail from [context]: a
  /// detail is registered AND the page is on planes under a host scope.
  /// What the identity-card pencil consults before it draws itself with
  /// no [ProfileSectionRegistry.onEditProfile] to fall back on.
  static bool canOpenEditProfile(BuildContext context) =>
      ProfileSectionRegistry.I.editProfileDetailBuilder != null &&
      _hostOf(context) != null;

  /// Opens the registry's [ProfileSectionRegistry.editProfileDetailBuilder]
  /// in the host's detail plane, under
  /// [ProfileSectionRegistry.editProfileDetailId]. True when it did; false
  /// — run [ProfileSectionRegistry.onEditProfile] instead, as before —
  /// while no detail is registered, there is no host scope, or the page
  /// is not on planes.
  static bool openEditProfile(BuildContext context) {
    final builder = ProfileSectionRegistry.I.editProfileDetailBuilder;
    if (builder == null) return false;
    return openDetail(
      context,
      id: ProfileSectionRegistry.editProfileDetailId,
      detailBuilder: builder,
    );
  }

  /// Pops the host's open detail back to its landing state. True when the
  /// host did; false — keep the caller's own pop — outside a host, or
  /// under a host that offers no [onClose].
  static bool close(BuildContext context) {
    final onClose = _hostOf(context)?.onClose;
    if (onClose == null) return false;
    onClose();
    return true;
  }

  @override
  bool updateShouldNotify(ProfileSectionNavigator oldWidget) =>
      openSectionId != oldWidget.openSectionId ||
      onOpen != oldWidget.onOpen ||
      onClose != oldWidget.onClose;
}
