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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:auto_route/auto_route.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'widgets/logout_modal.dart';
import 'widgets/sections_item.dart';
import 'widgets/edit_restaurant_modal.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/presentation/components/custom_toggle3.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/pages/profile/edit_profile_sheet.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_profile_footer.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_wallet_card.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:merchants_sdk/src/manager/application/main/main_provider.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/restaurant_provider.dart';
import 'package:merchants_sdk/src/manager/utils/restaurant_helpers.dart';

// The manager restaurant tab, rebuilt as a host of base_sdk's generic
// profile page (GenericProfilePage + ProfileSectionRegistry) — approved
// design 2026-08-28 (profile-host page, section 7): standard host header
// (identity card, theme toggle, sign-out), NO cover art (the old
// ShopBanner sliver is retired), and an edit pencil (shop-edit flow)
// trailing the shop title row — on the SHOP element, not the wallet card.
//
// Every content block of the old hand-built page returns as a registered
// section, top to bottom in the old order:
//   * 'merchants.open_toggle' (top-row action) — the old floating
//     Open/Closed CustomToggle, now riding the host's top controls row;
//     the old floating logout button maps to the host's sign-out
//     affordance (registry.onLogout, LogoutModal's confirmed branch).
//   * 'merchants.shop_info' — shop title + rating + promo/flash glyphs +
//     edit pencil (shop-edit flow) + description.
//   * 'merchants.working_hours' — today's working-hours pill.
//   * 'merchants.wallet' — base_sdk's BaseWalletCard (no action strip, no
//     history arrow), replacing the hand-built balance box; same data
//     source (the cached shop JSON's seller wallet).
//   * 'merchants.sections' — the Sections list (restaurant settings /
//     income / order history / notifications / sync issues / delete
//     account), links unchanged.
//   * 'base.footer' — base_sdk's default footer plus the old page's
//     bottom-nav scroll clearance.
//
// Tab-hosted wiring is untouched: the merchants home shell
// (pages/main/main_page.dart) still imports this page directly, so it
// carries no @RoutePage and the manifest declares no route for it (same
// contract as orders_sdk's OrdersHomePage).
//
// Route call-sites still route to the OWNING SDKs' installed pages:
// ManagerIncomeRoute (revenue_sdk), ManagerOrderHistoryRoute (orders_sdk).
// NotificationListRoute stays a HOST route until the comms_sdk consume
// repoints it (fork plan S-3/H-10).

/// Registers the merchant profile sections with base_sdk's
/// [ProfileSectionRegistry]. Idempotent (guarded, and the registry itself
/// is first-wins per id); called from [RestaurantPage]'s initState so the
/// registrations precede the host page's mount — the same ordering as a
/// boot-time di_hooks registration.
void registerMerchantProfileSections() {
  final registry = ProfileSectionRegistry.I;
  if (registry.contains('merchants.shop_info')) return;

  // The host's top-row sign-out button (behind the host's own logout
  // confirmation): the confirmed branch of the old floating logout
  // button's LogoutModal, verbatim. `??=` so a host that already owns
  // sign-out keeps its wiring.
  registry.onLogout ??= (context) {
    LocalStorage.logout();
    context.router.popUntilRoot();
    context.replaceRoute(const LoginRoute());
  };

  // The user-card edit pencil (chip 109, approved frame 4d 2026-08-30):
  // wiring onEditProfile turns on the host's own pencil in the unified
  // identity card (generic_profile_page.dart's gated IconButton), giving
  // the manager an edit-OWN-details path — the gap Ray reported after
  // the chip-243 shop-pencil move (PR #80). The target is base_sdk's
  // shared edit sheet (the shipped customer flow, promoted in base_sdk
  // 1.45.0), presented as the same drag bottom sheet the customer app
  // uses; its Save drives base_sdk's editProfileProvider into the
  // self-scoped update_user_profile endpoint. Distinct from the SHOP
  // pencil (chip 243) on the shop info row below, which stays untouched.
  // `??=` so a host that already owns the edit affordance keeps its
  // wiring.
  registry.onEditProfile ??= (context) {
    AppHelpers.showCustomModalBottomDragSheet(
      context: context,
      modal: (c) => EditProfileScreen(controller: c),
      isDarkMode: LocalStorage.getAppThemeMode(),
    );
  };

  // The old floating Open/Closed toggle, re-homed to the host's top
  // controls row (between the page title and the theme toggle).
  registry.registerTopRowAction(
    id: 'merchants.open_toggle',
    order: 10,
    builder: (context) => const MerchantOpenToggle(),
  );

  registry.register(ProfileSection(
    id: 'merchants.shop_info',
    order: 110,
    builder: (context) => const MerchantShopInfoSection(),
  ));

  registry.register(ProfileSection(
    id: 'merchants.working_hours',
    order: 120,
    builder: (context) => const MerchantWorkingHoursSection(),
  ));

  // The PRODUCTIVITY gate (approved frame 7e, chip 391 — Ray 2026-08-29
  // 15:06Z "we can expose it. that will be productivity gate", approved
  // 15:41Z): the composed-but-orphaned productivity_sdk /tasks page gains
  // its one entry point — a PRODUCTIVITY group with the Tasks row. Order
  // 125 slots it after the restaurant content (shop info + working hours)
  // and before the wallet: with the host's contiguous item-count balance
  // that CLOSES PLANE 1 under the restaurant group at two-plane widths,
  // while wallet / sections / footer keep plane 2 — exactly the approved
  // 7d distribution, per the 7e legend. The /tasks screen behind the door
  // is NOT designed here (coverage-map group M owns that pass); this
  // registration is gate exposure only.
  registry.register(ProfileSection(
    id: 'merchants.productivity',
    order: 125,
    builder: (context) => const MerchantProductivitySection(),
  ));

  registry.register(ProfileSection(
    id: 'merchants.wallet',
    order: 130,
    builder: (context) => const MerchantWalletSection(),
  ));

  registry.register(ProfileSection(
    id: 'merchants.sections',
    order: 140,
    builder: (context) => const MerchantSectionsList(),
  ));

  // base.footer override: the host's default meta-row footer plus the old
  // page's bottom clearance, so the last content clears the manager
  // shell's floating bottom bar (first-wins beats ensureDefaultSections,
  // which runs when the host mounts).
  registry.register(ProfileSection(
    id: BaseProfileFooter.sectionId,
    order: BaseProfileFooter.sectionOrder,
    builder: (context) => Column(
      children: [
        const BaseProfileFooter(),
        SizedBox(height: 100.h),
      ],
    ),
  ));
}

class RestaurantPage extends ConsumerStatefulWidget {
  const RestaurantPage({super.key});

  @override
  ConsumerState<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends ConsumerState<RestaurantPage> {
  @override
  void initState() {
    super.initState();
    registerMerchantProfileSections();
    // The legacy app fetched the shop at splash/login; in the composed app
    // those flows are host-owned and may not know this provider, so the tab
    // fetches lazily when it has no shop yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(restaurantProvider).shop == null) {
        ref.read(restaurantProvider.notifier).fetchMyShop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The old page's ScrollController listener drove the manager shell's
    // bottom-bar collapse; the host owns its own scroll view, so the same
    // signal now comes from scroll notifications bubbling out of it.
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.reverse) {
          ref.read(mainProvider.notifier).changeScrolling(true);
        } else if (notification.direction == ScrollDirection.forward) {
          ref.read(mainProvider.notifier).changeScrolling(false);
        }
        return false;
      },
      child: const GenericProfilePage(),
    );
  }
}

/// The Open/Closed shop toggle in the host's top controls row — the old
/// floating LogoutButton's CustomToggle without the blur chrome (the
/// logout half of that widget is the host's sign-out button now).
class MerchantOpenToggle extends ConsumerWidget {
  const MerchantOpenToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(restaurantProvider).shop?.open ?? false;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.r),
      child: CustomToggle(
        isText: true,
        key: UniqueKey(),
        controller: ValueNotifier<bool>(isOpen),
        onChange: (value) {
          ref.read(restaurantProvider.notifier).setOnlineOffline();
        },
      ),
    );
  }
}

/// The shop info block, carried over from the old page's list head: shop
/// title + rating row (promo / flash glyphs kept) and the description.
/// The title row now trails an edit pencil opening the shop-edit flow
/// ([EditRestaurantModal] — the same invocation as [MerchantSectionsList]'s
/// "Restaurant settings" row): the pencil belongs on the SHOP element it
/// edits, not on the wallet card.
/// Colors ride the host's mode-resolving text tokens instead of the old
/// white-scaffold blackColor so the block stays legible in dark mode.
class MerchantShopInfoSection extends ConsumerWidget {
  const MerchantShopInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantProvider);
    // base_sdk keeps the shop as raw JSON; typed state first, cached JSON
    // as fallback (legacy read the typed LocalStorage.getShop()).
    final shopJson = LocalStorage.getShopJson();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              RestaurantHelpers.truncate(
                state.shop?.translation?.title ??
                    (shopJson?['translation']?['title'] as String?) ??
                    "",
                16,
              ),
              style: AppStyle.interSemi(
                size: 22.sp,
                color: AppStyle.textPrimary,
              ),
            ),
            Container(
              width: 4.w,
              height: 4.h,
              margin: REdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppStyle.textGrey,
              ),
            ),
            Icon(
              Remix.star_smile_fill,
              color: AppStyle.starColor,
              size: 20.r,
            ),
            4.horizontalSpace,
            Text(
              state.shop?.avgRate ?? '0.0',
              style: AppStyle.interNormal(
                size: 12.sp,
                color: AppStyle.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              width: 22.w,
              height: 22.h,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppStyle.red,
              ),
              child: Icon(
                Remix.percent_fill,
                color: AppStyle.white,
                size: 12.r,
              ),
            ),
            14.horizontalSpace,
            Container(
              width: 22.w,
              height: 22.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppStyle.primary,
              ),
              child: Icon(Remix.flashlight_fill, size: 16.r),
            ),
            14.horizontalSpace,
            // The shop-edit pencil (approved fix 2026-08-28): it edits the
            // SHOP, so it rides the shop title row — moved here from its
            // earlier wallet-card overlay.
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Remix.pencil_line,
                size: 20.r,
                color: AppStyle.textPrimary,
              ),
              onPressed: () => AppHelpers.showCustomModalBottomSheet(
                paddingTop: MediaQuery.paddingOf(context).top + 60,
                context: context,
                modal: const EditRestaurantModal(),
                isDarkMode: false,
              ),
            ),
          ],
        ),
        Text(
          '${state.shop?.translation?.description}',
          style: AppStyle.interNormal(
            size: 13.sp,
            color: AppStyle.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Today's working-hours pill, verbatim from the old page (the Shop
/// Working Day mapping stays RestaurantHelpers').
class MerchantWorkingHoursSection extends ConsumerWidget {
  const MerchantWorkingHoursSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantProvider);
    return Container(
      height: 46.r,
      margin: EdgeInsets.only(top: 24.h, bottom: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppStyle.borderColor,
          width: 1.r,
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Remix.time_fill,
            size: 20.r,
            color: AppStyle.textPrimary,
          ),
          10.horizontalSpace,
          Builder(
            builder: (context) {
              final todayTime =
                  RestaurantHelpers.workingTimeForToday(state.shop);
              return RichText(
                text: TextSpan(
                  text: todayTime == null
                      ? ''
                      : '${AppHelpers.getTranslation(TrKeys.workingHours)}:',
                  style: AppStyle.interRegular(
                    color: AppStyle.textPrimary,
                    size: 12.sp,
                  ),
                  children: [
                    TextSpan(
                      text:
                          ' ${todayTime ?? AppHelpers.getTranslation(TrKeys.theRestaurantIsClosedToday)}',
                      style: AppStyle.interSemi(
                        color: AppStyle.textPrimary,
                        size: 13.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The shop balance as base_sdk's [BaseWalletCard] (approved parameter:
/// no actions strip, no history arrow — the old hand-built box had no
/// history navigation either, its bar-chart glyph was inert). The card
/// carries no edit pencil: the shop-edit pencil lives on the shop title
/// row ([MerchantShopInfoSection]), the element it actually edits.
/// No explicit snapshot is passed: with `wallet:` null the card
/// self-sources from the profile fetch (profileProvider, falling back
/// to LocalStorage.getWalletData()), which GenericProfilePage's
/// initState refreshes via get_user_profile — and that payload now
/// carries the merchant's live Wallet balance. The merchant IS the
/// logged-in user, so the profile wallet is the seller balance.
class MerchantWalletSection extends StatelessWidget {
  const MerchantWalletSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BaseWalletCard(
          actions: [],
          onHistory: null,
        ),
        16.verticalSpace,
      ],
    );
  }
}

/// The PRODUCTIVITY group (approved frame 7e, chip 391): a group title and
/// the Tasks row, the sole entry point for productivity_sdk's composed
/// /tasks page. Routes the same way the other hub rows route — the host's
/// generated route class (TasksRoute, from productivity_sdk's manifest
/// /tasks entry) via the already-imported app_router; manager composes
/// carry productivity_sdk (paas_manager composer.json), so the class is
/// always generated here.
///
/// The approved render's row glance ("3 open · 1 due today") is SEEDED
/// content, disclosed as such on the frame; live open/due counts need
/// productivity task data merchants_sdk cannot reach (ADR-005 — SDKs
/// import only base), so the demo compose seeds the approved glance line
/// and real composes show the plain row until the /tasks screen's own
/// design pass (coverage-map group M) wires a counts seam.
class MerchantProductivitySection extends StatelessWidget {
  const MerchantProductivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleAndIcon(title: AppHelpers.getTranslation(TrKeys.productivity)),
        20.verticalSpace,
        SectionsItem(
          title: AppHelpers.getTranslation(TrKeys.tasks),
          subtitle: AppConstants.isDemo ? '3 open · 1 due today' : null,
          icon: Remix.task_line,
          onTap: () => context.pushRoute(const TasksRoute()),
        ),
      ],
    );
  }
}

/// The Sections list, link for link from the old page's `_sections`
/// column (restaurant settings modal, income, order history,
/// notifications, sync issues, delete account behind the demo flag).
class MerchantSectionsList extends StatelessWidget {
  const MerchantSectionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleAndIcon(title: AppHelpers.getTranslation(TrKeys.sections)),
        20.verticalSpace,
        SectionsItem(
          title: AppHelpers.getTranslation(TrKeys.restaurantSettings),
          icon: Remix.restaurant_line,
          onTap: () => AppHelpers.showCustomModalBottomSheet(
            paddingTop: MediaQuery.paddingOf(context).top + 60,
            context: context,
            modal: const EditRestaurantModal(),
            isDarkMode: false,
          ),
        ),
        // QUICK FLOW (approved design strip section 42, chip 795): the
        // shop's order-automation surface — auto-accept, auto-complete at
        // Ready, and the till keypad's digit presets. Inserted SECOND,
        // right under Restaurant settings, because it is shop setup and
        // not a report; the other five rows are untouched.
        SectionsItem(
          title: AppHelpers.getTranslation(TrKeys.quickFlow),
          icon: Remix.flashlight_line,
          onTap: () => context.pushRoute(const ManagerQuickFlowRoute()),
        ),
        SectionsItem(
          title: AppHelpers.getTranslation(TrKeys.income),
          icon: Remix.line_chart_line,
          onTap: () => context.pushRoute(const ManagerIncomeRoute()),
        ),
        SectionsItem(
          title: AppHelpers.getTranslation(TrKeys.myOrderHistory),
          icon: Remix.history_line,
          onTap: () => context.pushRoute(const ManagerOrderHistoryRoute()),
        ),
        SectionsItem(
          title: AppHelpers.getTranslation(TrKeys.notifications),
          icon: Remix.notification_2_line,
          onTap: () => context.pushRoute(const NotificationListRoute()),
        ),
        // Park-and-surface: records whose offline push the backend rejected,
        // with per-record retry/discard (merchants_sdk's own installed page).
        SectionsItem(
          title: AppHelpers.getTranslation(TrKeys.syncIssues),
          icon: Remix.refresh_line,
          onTap: () => context.pushRoute(const ManagerSyncIssuesRoute()),
        ),
        if (!AppConstants.isDemo)
          SectionsItem(
            title: AppHelpers.getTranslation(TrKeys.deleteAccount),
            icon: Remix.logout_box_r_line,
            onTap: () {
              AppHelpers.showCustomModalBottomSheet(
                context: context,
                modal: const LogoutModal(isDeleteAccount: true),
                isDarkMode: false,
              );
            },
          ),
      ],
    );
  }
}
