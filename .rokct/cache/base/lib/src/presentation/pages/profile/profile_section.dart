// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import 'package:flutter/widgets.dart';

/// One section of the generic profile page.
///
/// Feature SDKs contribute sections at bootstrap (typically from a manifest
/// `di_hooks` entry, per ADR-005) via [ProfileSectionRegistry.register];
/// [GenericProfilePage] renders every registered section in [order].
class ProfileSection {
  /// Unique across all SDKs. A duplicate id is dropped (first wins).
  final String id;

  /// Render position; lower renders first. Ties break by [id].
  final int order;

  /// Builds the section's widget inside the page body.
  final Widget Function(BuildContext context) builder;

  /// Optional async visibility gate, resolved once when the page mounts.
  /// `null` means always visible; `false` or a thrown error hides the
  /// section (mirrors the lms admin-row gating pattern).
  final Future<bool> Function()? visible;

  const ProfileSection({
    required this.id,
    required this.order,
    required this.builder,
    this.visible,
  });
}

/// The named slots inside the generic profile page's identity header card.
///
/// The header card renders, in order: the identity row (avatar, name,
/// contact, role — with [badge] inline next to the name), then [stats],
/// then [plan]. Every slot is optional; a header with no slots filled is
/// pixel-identical to the slot-less header that shipped before base_sdk
/// 1.27.0.
enum ProfileHeaderSlot {
  /// A compact chip rendered inline to the right of the display name
  /// (grade-badge style). Keep it small — it shares the name's row.
  badge,

  /// A full-width row rendered under the identity row, separated from it
  /// by the card's hairline divider (e.g. a divided stat row).
  stats,

  /// A full-width strip rendered under the stats row (or under the
  /// identity row while the stats slot is empty), e.g. a plan/entitlement
  /// summary. The host leads the row with the shared plan glyph
  /// (Remix `vip_crown_line` in the app primary) — contributors supply
  /// only the row's content after the crown.
  plan,

  /// The back face of the header card. While claimed (and its gate, if
  /// any, resolves true), tapping the [plan] row flips the whole header
  /// card in place — no navigation — to a card of the same chrome
  /// rendering this slot's content (e.g. the plan's benefits); tapping
  /// the flipped card flips it back. With this slot unclaimed the plan
  /// row does not flip, and any tap handling belongs to the [plan]
  /// content itself.
  planBack,

  /// A small element pinned to the card's bottom-right corner (an icon
  /// affordance at most — it overlays the card's content area). Rendered
  /// on the front face only.
  corner,
}

/// One SDK contribution to a [ProfileHeaderSlot] of the generic profile
/// page's identity header.
///
/// Registered at bootstrap (a `di_hooks` manifest entry, per ADR-005) via
/// [ProfileSectionRegistry.registerHeaderSlot]; the header renders the
/// content inside its own card. Slot content should render
/// `SizedBox.shrink()` when it has nothing to show.
class ProfileHeaderSlotContent {
  /// Unique across all SDKs (diagnostics; mirrors [ProfileSection.id]).
  /// A slot claimed twice keeps its first registration.
  final String id;

  /// Builds the slot's widget inside the header card.
  final Widget Function(BuildContext context) builder;

  /// Optional async visibility gate, resolved once when the page mounts —
  /// the same contract as [ProfileSection.visible]: `null` means always
  /// visible; `false` or a thrown error keeps the slot empty.
  final Future<bool> Function()? visible;

  const ProfileHeaderSlotContent({
    required this.id,
    required this.builder,
    this.visible,
  });
}

/// One SDK contribution to the generic profile page's top controls row.
///
/// The host renders the row above the header card: the page title on the
/// left, then every registered action in [order], then the host-owned
/// theme toggle and the icon-only sign-out button. Registered at bootstrap
/// (a `di_hooks` manifest entry, per ADR-005) via
/// [ProfileSectionRegistry.registerTopRowAction]. Actions are compact icon
/// affordances (an `IconButton`-sized widget) — anything larger belongs in
/// a [ProfileSection].
class ProfileTopRowAction {
  /// Unique across all SDKs. A duplicate id is dropped (first wins).
  final String id;

  /// Render position within the row; lower renders first (closer to the
  /// title). Ties break by [id].
  final int order;

  /// Builds the action's widget inside the top row.
  final Widget Function(BuildContext context) builder;

  const ProfileTopRowAction({
    required this.id,
    required this.builder,
    this.order = 0,
  });
}
