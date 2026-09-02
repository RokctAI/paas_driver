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

/// One layout-agnostic profile action button, declared by a contributing
/// SDK.
///
/// Contributors describe only WHAT the button is — icon, label, tap
/// action — never how it is laid out. Registration happens at bootstrap
/// (a `di_hooks` manifest entry, per ADR-005) via
/// [ProfileSectionRegistry.registerAction] into a page-keyed group (e.g.
/// `'marketplace.customer'`, `'lms.student'`); the SDK that owns the page
/// renders the group through a [ProfileActionsSection] and picks the
/// layout — square tiles or settings rows — so a contribution can never
/// clash with the host page's shape.
class ProfileActionItem {
  /// Unique within its group, across all SDKs. A duplicate id is dropped
  /// (first wins), mirroring [ProfileSection.id].
  final String id;

  /// The action's glyph, rendered by whichever layout the page owner
  /// picked.
  final IconData icon;

  /// The action's label, resolved lazily at build time so translations
  /// (AppHelpers.getTranslation) reflect the active locale rather than
  /// the locale at registration.
  final String Function() label;

  /// Invoked when the user taps the action, with the tapping widget's
  /// [BuildContext] (for navigation, dialogs, etc.).
  final void Function(BuildContext context) onTap;

  /// Render position within the group; lower renders first. Ties break by
  /// [id].
  final int order;

  /// Optional async visibility gate, resolved once when the rendering
  /// section mounts — the same contract as [ProfileSection.visible]:
  /// `null` means always visible; `false` or a thrown error hides the
  /// action.
  final Future<bool> Function()? visible;

  /// Optional small badge rendered on top of the action (e.g. an unread
  /// count chip). Keep it compact — it overlays the icon in the grid
  /// layout and sits before the chevron in the rows layout.
  final Widget Function(BuildContext context)? badgeBuilder;

  /// Optional accent color for the action's icon. Null renders the shared
  /// primary-text tone.
  final Color? accent;

  const ProfileActionItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
    this.order = 0,
    this.visible,
    this.badgeBuilder,
    this.accent,
  });
}
