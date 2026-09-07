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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/application/app_widget/app_provider.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
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
/// page sits in a two-plane [PlaneHost] — the universal profile cap:
/// two planes at most, the leftover plane trailing as a bare stage at
/// the END on the page surface — and, because the routed profile is a
/// PUSHED page (`pushGenericProfileRoute`), it carries the pushed page's
/// one back: the [FloatingBackPill] at the bottom-END corner, exactly
/// where [PlaneHost] parks its own pill (frame 1d; "back button should
/// always be at a corner"). The pill shows only while the route can pop,
/// so a composition that opens on the profile never draws a dead back.
///
/// On a phone (one plane) the page is [GenericProfilePage] exactly as
/// before — no host, no pill; the platform back is the phone's back.
class GenericProfileRoutePage extends ConsumerWidget {
  const GenericProfileRoutePage({super.key});

  /// The identity of the profile step in the host's flow.
  static const String planePageName = 'generic-profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-resolve the stage surface when the theme toggle flips the
    // persisted mode, the same way the page itself does.
    ref.watch(appProvider.select((s) => s.isDarkMode));
    return LayoutBuilder(
      builder: (context, constraints) {
        if (PlaneHost.planeCountFor(constraints.maxWidth) < 2) {
          return const GenericProfilePage();
        }
        final canPop = Navigator.maybeOf(context)?.canPop() ?? false;
        return ColoredBox(
          // The bare stage beyond the profile's two planes is the page
          // surface, not the route's canvas.
          color: AppStyle.surfaceDark,
          child: Stack(
            children: [
              Positioned.fill(
                child: PlaneHost(
                  stack: [
                    PlanePage(
                      name: planePageName,
                      span: PlaneSpan.two,
                      builder: (context) => const GenericProfilePage(),
                    ),
                  ],
                ),
              ),
              if (canPop)
                PositionedDirectional(
                  end: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: FloatingBackPill(
                      back: FloatingNavBack(
                        icon: Remix.arrow_left_wide_fill,
                        label: AppHelpers.getTranslation(TrKeys.back),
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
