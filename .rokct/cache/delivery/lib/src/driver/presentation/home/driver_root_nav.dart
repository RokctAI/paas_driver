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

// CHIP 301 of design strip section 49 — the driver app's ROOT TAB SET,
// stamped on frames 49a, 49c, 49d, 49e and 49m: Home · Jobs · Route ·
// Income · Profile.
//
// THE NAV IS AN ADOPTION, AND IT WAS OVERDUE. `FloatingBottomNav` is
// already the driver app's nav language — route_page, order_history,
// parcel_history and revenue's income_page all mount it — and home was
// the one driver page that did not, pinning four free-floating icon
// buttons down the left edge instead. Every sibling also mounted the
// pill with `tabs: const []`, because, in the shipped comment's own
// words, "the driver app composes no root tab set". This file is that
// tab set: the one genuinely new structural proposal in section 49,
// called out as such rather than smuggled in.
//
// WHAT THIS FILE OWNS AND WHAT IT DOES NOT. The five destinations are
// named here as [DriverRootTab] so a test can pin their order and their
// count without a router. WHERE each one goes is the host's business:
// the routes (`OrdersRoute`, `DriverRouteRoute`, `DriverIncomeRoute`,
// `ProfileRoute`) are generated classes of the composed app, so the
// installed home template maps a tab to a route and this SDK file never
// imports one (ADR-005 — lib/ imports only base_sdk).
//
// THE ACTIVE MARK. The frames draw the active tab as a filled pill in the
// brand primary behind its icon and label — `FloatingNavIndicator
// .rectangle`, the pill's own second look — rather than the original
// dash. Per-host, not per-app: this is the driver host's choice.
//
// TABLET MODE. Section 49 is phone-only by its own admission (no wide
// pass was drawn), so this nav passes NO `tabletPlacement` and inherits
// the fleet default — the floating bottom pill in every window size,
// exactly Ray's 2026-08-26 ruling. A driver wide pass, if one is ever
// drawn, is where a rail would be decided; not here.

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

/// The five root destinations, in the order the frames draw them.
///
/// `index` IS the pill's tab index — do not reorder without redrawing.
enum DriverRootTab { home, jobs, route, income, profile }

/// The vertical room a bottom sheet must leave under its last child so
/// nothing it draws is buried under the floating pill.
///
/// The pill is `60.r` tall and floats `18.h` above the safe-area edge
/// (both `FloatingBottomNav`'s own figures); the extra `12.h` is the gap
/// the frames leave between the last card and the pill. The safe-area
/// inset itself is NOT included — every sheet already adds
/// `MediaQuery.paddingOf(context).bottom` on its own.
double driverRootNavClearance() => 60.r + 18.h + 12.h;

/// CHIP 301 — the five tabs as the pill wants them.
///
/// Labels are the frames' words. Home / Income / Profile are base keys;
/// Jobs and Route are courier vocabulary declared in this SDK's manifest.
List<FloatingNavTab> driverRootTabs() => [
  FloatingNavTab(
    selectIcon: Remix.home_5_fill,
    unSelectIcon: Remix.home_5_line,
    label: AppHelpers.getTranslation(TrKeys.home),
  ),
  FloatingNavTab(
    selectIcon: Remix.file_list_2_fill,
    unSelectIcon: Remix.file_list_2_line,
    label: AppHelpers.getTranslation(TrKeys.jobs),
  ),
  FloatingNavTab(
    selectIcon: Remix.route_fill,
    unSelectIcon: Remix.route_line,
    label: AppHelpers.getTranslation(TrKeys.route),
  ),
  FloatingNavTab(
    selectIcon: Remix.money_dollar_circle_fill,
    unSelectIcon: Remix.money_dollar_circle_line,
    label: AppHelpers.getTranslation(TrKeys.income),
  ),
  FloatingNavTab(
    selectIcon: Remix.user_fill,
    unSelectIcon: Remix.user_line,
    label: AppHelpers.getTranslation(TrKeys.profile),
  ),
];

/// CHIP 301 mounted: the shared pill carrying the driver root tab set.
///
/// [current] is passed down by the page on screen, never stored — the
/// same rule the pill applies to every mode it renders. Home lights
/// Home while the driver idles (49a, 49d, 49e) and lights JOBS while he
/// is inside a job (49c): a driver mid-job is inside the job, and the
/// nav says so rather than pretending he is idling on Home.
///
/// [onSelect] reports every tap, the current tab included; the host
/// decides what a tap on the lit tab means (on home: nothing to do).
class DriverRootNav extends StatelessWidget {
  const DriverRootNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final DriverRootTab current;
  final ValueChanged<DriverRootTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return FloatingBottomNav(
      mode: FloatingNavTabsMode(
        tabs: driverRootTabs(),
        currentIndex: current.index,
        onSelect: (index) => onSelect(DriverRootTab.values[index]),
        indicator: FloatingNavIndicator.rectangle,
      ),
    );
  }
}
