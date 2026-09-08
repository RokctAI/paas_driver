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


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/application/app_widget/app_provider.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_navigator.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The routed `/generic-profile` page: [GenericProfilePage] on planes.
///
/// [GenericProfilePage] spreads only under a [PlaneHost] (the approved
/// plane proposal, frame 1c, capped at two planes by the 4c ruling); on
/// an ordinary route it renders its phone list, which a wide window
/// simply stretches. Every composed app mounts the page through the
/// `/generic-profile` route in base_sdk's own route shell, so the host
/// lives HERE, once — no shell needs a wrapper of its own.
///
/// At plane widths (two or more planes, [PlaneHost.planeCountFor]) the
/// page sits in a [PlaneHost] whose root is the profile, declared
/// [PlaneSpan.two] — the universal profile cap: two planes at most — and,
/// because the routed profile is a PUSHED page (`pushGenericProfileRoute`),
/// it carries the pushed page's one back: the [FloatingBackPill] at the
/// bottom-END corner, exactly where [PlaneHost] parks its own pill (frame
/// 1d; "back button should always be at a corner"). The pill shows only
/// while there is somewhere to go back to, so a composition that opens on
/// the profile never draws a dead back.
///
/// The host's DETAIL PLANE (Ray 2026-09-07, "on a tablet the generic
/// profile host must not leave the third plane empty"): a section that
/// declares a [ProfileSection.detailBuilder] opens IN the host — its
/// detail is pushed onto the plane stack as the active step with the
/// default one-plane claim, so it takes the LAST plane and the profile
/// yields but keeps spreading over the two before it (three planes), or
/// compresses to its phone layout beside the detail (two planes). Cards
/// reach this through [ProfileSectionNavigator.open]. On a THREE-plane
/// screen the registry's [ProfileSectionRegistry.defaultSectionId] is
/// open from the first frame, so the profile lands with its third plane
/// filled; another section's detail replaces it, and the corner pill
/// returns to the default before it pops the route. On two planes nothing
/// is seeded — the profile keeps both planes until a card opens a detail.
/// A detail with no hub card — the edit-profile form the registry's
/// [ProfileSectionRegistry.editProfileDetailBuilder] supplies, opened by
/// the identity-card pencil or [ProfileSectionNavigator.openEditProfile]
/// — takes the same plane the same way, and the same pill returns from it;
/// the detail itself may leave through [ProfileSectionNavigator.close]
/// (a saved form), which is the pill's first step without the tap.
///
/// On a phone (one plane) the page is [GenericProfilePage] exactly as
/// before — no host, no pill, no seam; the platform back is the phone's
/// back and every card pushes the route it always did.
class GenericProfileRoutePage extends ConsumerStatefulWidget {
  const GenericProfileRoutePage({super.key});

  /// The identity of the profile step in the host's flow.
  static const String planePageName = 'generic-profile';

  /// The identity of a section's detail step in the host's flow.
  static String detailPageName(String sectionId) =>
      'generic-profile-detail-$sectionId';

  @override
  ConsumerState<GenericProfileRoutePage> createState() =>
      _GenericProfileRoutePageState();
}

class _GenericProfileRoutePageState
    extends ConsumerState<GenericProfileRoutePage> {
  /// The section whose detail a card opened last, or null while none did
  /// (the detail plane then shows the default on three planes, nothing on
  /// two). The corner pill clears it — back to the landing state.
  ProfileSection? _opened;

  /// The registry's default section once it may be shown: at once when
  /// the section has no gate, after its gate resolves true otherwise —
  /// the same resolve-once contract [GenericProfilePage] applies to the
  /// section's card. Null while there is no default to seed.
  ProfileSection? _default;

  @override
  void initState() {
    super.initState();
    _resolveDefault();
  }

  void _resolveDefault() {
    final section = ProfileSectionRegistry.I.defaultSection;
    if (section == null) return;
    // What the composition cannot host, it does not seed either — the
    // same facade check the page applies before a section's own gate.
    final capabilities = ref.read(profileProvider.notifier).capabilities;
    if (!capabilities.satisfies(section.requires)) return;
    final gate = section.visible;
    if (gate == null) {
      _default = section;
      return;
    }
    unawaited(() async {
      var visible = false;
      try {
        visible = await gate();
      } catch (_) {
        visible = false;
      }
      if (!mounted || !visible) return;
      setState(() => _default = section);
    }());
  }

  void _open(ProfileSection section) {
    setState(() => _opened = section);
  }

  /// Back to the landing state: the default on three planes, the bare
  /// stage on two. The pill's first step, and an embedded detail's own
  /// way out ([ProfileSectionNavigator.close]).
  void _close() {
    if (_opened == null) return;
    setState(() => _opened = null);
  }

  @override
  Widget build(BuildContext context) {
    // Re-resolve the stage surface when the theme toggle flips the
    // persisted mode, the same way the page itself does.
    ref.watch(appProvider.select((s) => s.isDarkMode));
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = PlaneHost.planeCountFor(constraints.maxWidth);
        if (count < 2) {
          return const GenericProfilePage();
        }
        // The detail plane's content: what a card opened, else — on three
        // planes only — the default. Two planes seed nothing: the profile
        // keeps both until a card opens a detail beside it. Opening the
        // seeded default is returning to it, not a step of its own: the
        // pill then pops the route, never the landing state.
        final seeded = count >= 3 ? _default : null;
        final opened = identical(_opened, seeded) ? null : _opened;
        final detail = opened ?? seeded;
        final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
        return ColoredBox(
          // The bare stage beyond the profile's planes is the page
          // surface, not the route's canvas.
          color: AppStyle.surfaceDark,
          child: Stack(
            children: [
              Positioned.fill(
                child: ProfileSectionNavigator(
                  onOpen: _open,
                  onClose: _close,
                  openSectionId: detail?.id,
                  child: PlaneHost(
                    stack: [
                      PlanePage(
                        name: GenericProfileRoutePage.planePageName,
                        span: PlaneSpan.two,
                        builder: (context) => const GenericProfilePage(),
                      ),
                      if (detail != null)
                        PlanePage(
                          // Default claim — exactly one plane, the LAST.
                          name: GenericProfileRoutePage.detailPageName(
                            detail.id,
                          ),
                          builder: detail.detailBuilder!,
                        ),
                    ],
                  ),
                ),
              ),
              // The one back: an opened detail pops first (back to the
              // default, or to the bare stage); the route pops after.
              if (canPop || opened != null)
                PositionedDirectional(
                  end: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: FloatingBackPill(
                      back: FloatingNavBack(
                        icon: Remix.arrow_left_wide_fill,
                        label: AppHelpers.getTranslation(TrKeys.back),
                        onTap: opened == null ? null : _close,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
