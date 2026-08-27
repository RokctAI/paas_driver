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

  /// Header edit affordance; hidden while unset. Registered by the shell
  /// or an SDK that owns the edit-profile flow.
  void Function(BuildContext context)? onEditProfile;

  /// Header logout affordance; hidden while unset. Invoked after the user
  /// confirms the logout dialog — the callback owns the actual sign-out
  /// and post-logout navigation.
  void Function(BuildContext context)? onLogout;

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
    onEditProfile = null;
    onLogout = null;
  }
}
