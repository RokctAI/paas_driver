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


// The driver's contribution to base_sdk's generic profile host (design
// strip section 1: the unified header on EVERY profile page, frame 1c's
// two-plane spread). Everything the retired standalone driver profile page
// showed is re-homed here as registry content:
//
//   * the balance / last profit / delivered tiles -> the header card's
//     `stats` slot ([DriverProfileStatsRow], registered by the installed
//     shell because the figures come from the host-installed statistics
//     provider);
//   * the row list (profile settings, delivery zone, orders, parcels,
//     notifications, order history, parcel history, income, language,
//     delete account) -> ONE `delivery.driver_rows` section of base
//     ProfileNavTiles;
//   * the Online helper call button -> the `delivery.online_helper`
//     section;
//   * the sign-out glyph -> the host's top-row sign-out (`onLogout`), and
//     the settings sheet -> the header pencil (`onEditProfile`) AS WELL AS
//     the Profile settings row (users_sdk's tour taps that row by its
//     translated title). At plane widths the settings form is the
//     profile's DETAIL PANE instead (Ray 2026-09-08, the sheet fork
//     ruling: "sheet = PHONE, plane widths get a pane"): the shell's
//     [DriverProfileActions.profileSettingsDetail] becomes the registry's
//     `editProfileDetailBuilder` (base_sdk 1.60.11), the pencil opens it
//     through the host and the row through
//     [ProfileSectionNavigator.openEditProfile]; on a phone both fall back
//     to the sheet exactly as before.
//
// Destinations are generated route classes of the composed app, so they
// arrive as callbacks ([DriverProfileActions]) from the installed
// profile_page.dart shell - this file imports only base_sdk, like every
// other lib/ widget of the driver role.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_navigator.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_profile_footer.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/profile_nav_tile.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/profile_section_card.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Where each row of the driver profile goes. Every callback receives the
/// tapping tile's [BuildContext]; the installed shell fills them with the
/// composed app's routes and sheets.
class DriverProfileActions {
  final void Function(BuildContext context) onProfileSettings;
  final void Function(BuildContext context) onDeliveryZone;
  final void Function(BuildContext context) onOrders;
  final void Function(BuildContext context) onParcels;
  final void Function(BuildContext context) onNotifications;
  final void Function(BuildContext context) onOrderHistory;
  final void Function(BuildContext context) onParcelHistory;
  final void Function(BuildContext context) onIncome;
  final void Function(BuildContext context) onLanguage;

  /// Null hides the row - the old page hid Delete account in demo builds.
  final void Function(BuildContext context)? onDeleteAccount;

  /// The Online helper call.
  final void Function(BuildContext context) onOnlineHelper;

  /// The Order history row's content EMBEDDED for a plane host's detail
  /// plane (base_sdk 1.60.10: [ProfileSection.detailBuilder]) - the same
  /// list [onOrderHistory] pushes, without its Scaffold, app bar or back.
  /// The installed shell supplies it from the composed app's order-history
  /// page; null (the default) declares no detail, so the rows section is
  /// never the registry's default and every row pushes as before.
  final WidgetBuilder? orderHistoryDetail;

  /// The Profile settings form EMBEDDED for a plane host's detail plane
  /// (base_sdk 1.60.11: `ProfileSectionRegistry.editProfileDetailBuilder`)
  /// - the same form [onProfileSettings] opens as a sheet, without the
  /// sheet's rounded card, top-aligned in the plane, its Save leaving the
  /// pane through `ProfileSectionNavigator.close`. The installed shell
  /// supplies it (the form is a template widget of the composed app);
  /// null (the default) registers no detail, so the pencil and the row
  /// open the sheet everywhere, as before.
  final WidgetBuilder? profileSettingsDetail;

  const DriverProfileActions({
    required this.onProfileSettings,
    required this.onDeliveryZone,
    required this.onOrders,
    required this.onParcels,
    required this.onNotifications,
    required this.onOrderHistory,
    required this.onParcelHistory,
    required this.onIncome,
    required this.onLanguage,
    required this.onDeleteAccount,
    required this.onOnlineHelper,
    this.orderHistoryDetail,
    this.profileSettingsDetail,
  });
}

class DriverProfileSections {
  DriverProfileSections._();

  /// The header card's stats slot - claimed by the installed shell with a
  /// [DriverProfileStatsRow] fed from the host statistics provider.
  static const String statsSlotId = 'delivery.driver_stats';

  static const String rowsId = 'delivery.driver_rows';
  static const int rowsOrder = 110;

  /// The section a plane host opens BY DEFAULT (tablet audit 2026-09-07,
  /// 16-users_profile: the driver profile left its third plane empty).
  ///
  /// The driver profile has ONE content section - the row list - so the
  /// choice is which row's content that section's detail plane carries.
  /// Income would be the driver's first pick, but it is revenue_sdk's
  /// route page (its own Scaffold, tabs and withdraw flow; a revenue_sdk
  /// change to embed, recorded as a follow-up). Order history is the
  /// next: it is the courier's own record, the list the header's
  /// "delivered" and "last profit" figures summarise, and it is this
  /// SDK's page, so the shell can embed its content without a second
  /// Scaffold. The Order history row opens it through
  /// [ProfileSectionNavigator.open]; on a phone the seam answers false
  /// and the row pushes exactly as before.
  static const String defaultSectionId = rowsId;

  static const String onlineHelperId = 'delivery.online_helper';
  static const int onlineHelperOrder = 120;

  /// Space the last section leaves under itself so the floating back pill
  /// never covers the footer - the same clearance merchants' hub reserves.
  static double navClearance() => 100.h;

  /// Registers the driver's sections with base_sdk's registry. Idempotent:
  /// a second call (the profile route pushed again) changes nothing, the
  /// registry's first-wins rule and the guard below agree.
  static void register({required DriverProfileActions actions}) {
    final registry = ProfileSectionRegistry.I;
    if (registry.contains(rowsId)) return;

    registry.register(
      ProfileSection(
        id: rowsId,
        order: rowsOrder,
        builder: (context) => DriverProfileRows(actions: actions),
        detailBuilder: actions.orderHistoryDetail,
      ),
    );
    // Seeded into the third plane on a three-plane screen by the plane
    // host (GenericProfileRoutePage); a section without a detail cannot be
    // the default, so a shell that supplies none leaves the plane bare.
    if (actions.orderHistoryDetail != null) {
      registry.defaultSectionId ??= defaultSectionId;
    }

    // The settings form as the detail pane at plane widths (Ray
    // 2026-09-08). First-wins like every other registry slot: an SDK that
    // registered an edit detail before the driver keeps it.
    final settingsDetail = actions.profileSettingsDetail;
    if (settingsDetail != null) {
      registry.editProfileDetailBuilder ??= settingsDetail;
    }

    registry.register(
      ProfileSection(
        id: onlineHelperId,
        order: onlineHelperOrder,
        builder: (context) => DriverOnlineHelperSection(
          onTap: () => actions.onOnlineHelper(context),
        ),
      ),
    );

    // The host fills base.footer with its meta row when nothing claimed
    // it; claiming it here keeps that row and adds the pill clearance
    // under it (duplicate id = first registration wins, and this runs
    // before the host's ensureDefaultSections).
    registry.register(
      ProfileSection(
        id: BaseProfileFooter.sectionId,
        order: BaseProfileFooter.sectionOrder,
        builder: (context) => Column(
          children: [
            const BaseProfileFooter(),
            SizedBox(height: navClearance()),
          ],
        ),
      ),
    );
  }
}

/// The retired page's two tiles as the unified header's divided stat row:
/// balance | last profit | delivered orders.
class DriverProfileStatsRow extends StatelessWidget {
  final num? balance;
  final num? lastProfit;
  final num deliveredOrders;

  const DriverProfileStatsRow({
    super.key,
    required this.balance,
    required this.lastProfit,
    required this.deliveredOrders,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Stat(
              label: AppHelpers.getTranslation(TrKeys.balance),
              value: AppHelpers.numberFormat(number: balance ?? 0),
            ),
          ),
          VerticalDivider(width: 1, color: AppStyle.strokeDark),
          Expanded(
            child: _Stat(
              label: AppHelpers.getTranslation(TrKeys.lastProfit),
              value: AppHelpers.numberFormat(number: lastProfit ?? 0),
              valueColor: AppStyle.primary,
            ),
          ),
          VerticalDivider(width: 1, color: AppStyle.strokeDark),
          Expanded(
            child: _Stat(
              label: AppHelpers.getTranslation(TrKeys.deliveredOrder),
              value: deliveredOrders.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Stat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppStyle.interNormal(
              size: 12.sp,
              color: AppStyle.textDarkSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          2.verticalSpace,
          Text(
            value,
            style: AppStyle.interSemi(
              size: 14.sp,
              color: valueColor ?? AppStyle.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// The row list, in the retired page's order.
class DriverProfileRows extends StatelessWidget {
  final DriverProfileActions actions;

  const DriverProfileRows({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final onDeleteAccount = actions.onDeleteAccount;
    return ProfileSectionCard(
      child: Column(
        children: [
          ProfileNavTile(
            icon: Remix.user_settings_line,
            title: AppHelpers.getTranslation(TrKeys.profileSettings),
            onTap: () {
              // Plane widths: the form in the host's detail plane (the
              // same pane the header pencil opens); a phone, or a shell
              // that registered no detail, gets the sheet as before.
              if (ProfileSectionNavigator.openEditProfile(context)) return;
              actions.onProfileSettings(context);
            },
          ),
          ProfileNavTile(
            icon: Remix.navigation_fill,
            title: AppHelpers.getTranslation(TrKeys.deliveryZone),
            onTap: () => actions.onDeliveryZone(context),
          ),
          ProfileNavTile(
            icon: Remix.order_play_line,
            title: AppHelpers.getTranslation(TrKeys.orders),
            onTap: () => actions.onOrders(context),
          ),
          ProfileNavTile(
            icon: Remix.archive_line,
            title: AppHelpers.getTranslation(TrKeys.parcels),
            onTap: () => actions.onParcels(context),
          ),
          ProfileNavTile(
            icon: Remix.notification_2_line,
            title: AppHelpers.getTranslation(TrKeys.notifications),
            onTap: () => actions.onNotifications(context),
          ),
          ProfileNavTile(
            icon: Remix.history_line,
            title: AppHelpers.getTranslation(TrKeys.orderHistory),
            onTap: () {
              // On planes the host opens the detail beside the profile;
              // anywhere else (a phone, no host scope, no detail) the seam
              // answers false and the row pushes as it always did.
              if (ProfileSectionNavigator.open(
                context,
                DriverProfileSections.defaultSectionId,
              )) {
                return;
              }
              actions.onOrderHistory(context);
            },
          ),
          ProfileNavTile(
            icon: Remix.folder_history_fill,
            title: AppHelpers.getTranslation(TrKeys.parcelHistory),
            onTap: () => actions.onParcelHistory(context),
          ),
          ProfileNavTile(
            icon: Remix.line_chart_line,
            title: AppHelpers.getTranslation(TrKeys.income),
            onTap: () => actions.onIncome(context),
          ),
          ProfileNavTile(
            icon: Remix.global_line,
            title: AppHelpers.getTranslation(TrKeys.language),
            onTap: () => actions.onLanguage(context),
          ),
          if (onDeleteAccount != null)
            ProfileNavTile(
              icon: Remix.logout_box_r_line,
              title: AppHelpers.getTranslation(TrKeys.deleteAccount),
              onTap: () => onDeleteAccount(context),
            ),
        ],
      ),
    );
  }
}

/// The Online helper call - the retired page's bottom button, now a body
/// section so it spreads with the rest on wide windows.
class DriverOnlineHelperSection extends StatelessWidget {
  final VoidCallback onTap;

  const DriverOnlineHelperSection({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.r),
      child: CustomButton(
        title: AppHelpers.getTranslation(TrKeys.onlineHelper),
        textColor: AppStyle.white,
        onPressed: onTap,
        icon: Icon(
          Remix.chat_smile_2_fill,
          color: AppStyle.white,
          size: 20.r,
        ),
      ),
    );
  }
}
