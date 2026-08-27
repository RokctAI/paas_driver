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


import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_profile_footer.dart';

/// Cross-SDK section registry backing the generic profile page.
///
/// Feature SDKs must not import each other (ADR-005), so each SDK registers
/// its sections here at bootstrap — typically a `di_hooks` manifest entry
/// calling `ProfileSectionRegistry.I.register(...)` — and the page composes
/// whatever the installed SDK set contributed. Unlike [EmbeddedWidgets],
/// the contributor set is open-ended, so this is a runtime collection
/// rather than a fixed method surface.
class ProfileSectionRegistry {
  ProfileSectionRegistry._();

  static final ProfileSectionRegistry I = ProfileSectionRegistry._();

  final Map<String, ProfileSection> _sections = {};

  final Map<ProfileHeaderSlot, ProfileHeaderSlotContent> _headerSlots = {};

  final Map<String, ProfileTopRowAction> _topRowActions = {};

  /// Header edit affordance; hidden while unset. Registered by the shell
  /// or an SDK that owns the edit-profile flow.
  void Function(BuildContext context)? onEditProfile;

  /// Sign-out affordance — the top row's icon-only round red button;
  /// hidden while unset. Invoked after the user confirms the logout
  /// dialog — the callback owns the actual sign-out and post-logout
  /// navigation.
  void Function(BuildContext context)? onLogout;

  /// Overridable top-row page title. Null (the default) renders the
  /// host's own title — the translated `profile` key. An SDK that owns
  /// the profile surface may set a different title at bootstrap.
  String? pageTitle;

  /// Registers [section]. Duplicate id: first registration wins and the
  /// duplicate is dropped loudly — the same semantics as the installer's
  /// embedded_widgets/onboarding_slides composers.
  void register(ProfileSection section) {
    if (_sections.containsKey(section.id)) {
      assert(() {
        debugPrint(
            "ProfileSectionRegistry: duplicate section id '${section.id}' "
            'ignored - the first registration wins.');
        return true;
      }());
      return;
    }
    _sections[section.id] = section;
  }

  /// Whether a section with [id] is already registered.
  bool contains(String id) => _sections.containsKey(id);

  /// Claims [slot] of the identity header card with SDK-supplied content.
  ///
  /// The header card renders the slots around the identity row (see
  /// [ProfileHeaderSlot]); a header with no slots claimed renders exactly
  /// as it did before slots existed. Like [register], registration happens
  /// at bootstrap (`di_hooks`), and a slot claimed twice keeps its first
  /// registration — the duplicate is dropped loudly. [visible] follows
  /// [ProfileSection.visible]'s contract: resolved once when the page
  /// mounts; `false` or a throw keeps the slot empty.
  void registerHeaderSlot(
    ProfileHeaderSlot slot, {
    required String id,
    required Widget Function(BuildContext context) builder,
    Future<bool> Function()? visible,
  }) {
    final existing = _headerSlots[slot];
    if (existing != null) {
      assert(() {
        debugPrint(
            "ProfileSectionRegistry: header slot '${slot.name}' already "
            "claimed by '${existing.id}' - '$id' ignored, the first "
            'registration wins.');
        return true;
      }());
      return;
    }
    _headerSlots[slot] =
        ProfileHeaderSlotContent(id: id, builder: builder, visible: visible);
  }

  /// The content claiming [slot], or null while the slot is unclaimed.
  ProfileHeaderSlotContent? headerSlot(ProfileHeaderSlot slot) =>
      _headerSlots[slot];

  /// Whether [slot] of the identity header is already claimed.
  bool containsHeaderSlot(ProfileHeaderSlot slot) =>
      _headerSlots.containsKey(slot);

  /// Registers a compact action for the host's top controls row (rendered
  /// between the page title and the host-owned theme toggle / sign-out).
  ///
  /// Like [register], registration happens at bootstrap (`di_hooks`), and
  /// a duplicate [id] keeps its first registration — the duplicate is
  /// dropped loudly. Actions render in [order] (lower first, ties broken
  /// by id).
  void registerTopRowAction({
    required String id,
    required Widget Function(BuildContext context) builder,
    int order = 0,
  }) {
    if (_topRowActions.containsKey(id)) {
      assert(() {
        debugPrint(
            "ProfileSectionRegistry: duplicate top-row action id '$id' "
            'ignored - the first registration wins.');
        return true;
      }());
      return;
    }
    _topRowActions[id] =
        ProfileTopRowAction(id: id, builder: builder, order: order);
  }

  /// Whether a top-row action with [id] is already registered.
  bool containsTopRowAction(String id) => _topRowActions.containsKey(id);

  /// Registered top-row actions sorted by [ProfileTopRowAction.order],
  /// ties broken by id — the same deterministic ordering as [sections].
  List<ProfileTopRowAction> get topRowActions {
    final list = _topRowActions.values.toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    return list;
  }

  /// Registers base_sdk's default sections for every slot no SDK claimed.
  ///
  /// Called by the generic profile host when it mounts — after every
  /// bootstrap (`di_hooks`) registration has run — so SDK registrations
  /// always precede it. Today there is one default: the `base.footer`
  /// meta row ([BaseProfileFooter]: app name, version, Online/Offline
  /// dot, [AppUsageBadge]-style usage figures) at order
  /// [BaseProfileFooter.sectionOrder].
  ///
  /// Because duplicate ids are first-wins and this runs last, an SDK
  ///   * overrides the default by registering its own section with id
  ///     [BaseProfileFooter.sectionId] at bootstrap, and
  ///   * hides the footer slot entirely by registering a
  ///     [BaseProfileFooter.sectionId] section whose `visible` gate
  ///     resolves false.
  ///
  /// Idempotent: calling it again never duplicates a default.
  void ensureDefaultSections() {
    // Transitional guard (no SDK import — a string id only): marketplace_sdk
    // < 1.6.0 still ships its own full footer, meta row included, under the
    // legacy 'marketplace.footer' id. Skip the default there so the row is
    // not rendered twice while base_sdk 1.26 and marketplace_sdk 1.6 roll
    // out independently. Remove once no composed app pins marketplace_sdk
    // < 1.6.0.
    if (contains('marketplace.footer')) return;

    if (!contains(BaseProfileFooter.sectionId)) {
      register(ProfileSection(
        id: BaseProfileFooter.sectionId,
        order: BaseProfileFooter.sectionOrder,
        builder: (context) => const BaseProfileFooter(),
      ));
    }
  }

  /// Registered sections sorted by [ProfileSection.order], ties broken by
  /// id so the layout is deterministic across bootstraps.
  List<ProfileSection> get sections {
    final list = _sections.values.toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    return list;
  }

  @visibleForTesting
  void reset() {
    _sections.clear();
    _headerSlots.clear();
    _topRowActions.clear();
    onEditProfile = null;
    onLogout = null;
    pageTitle = null;
  }
}
