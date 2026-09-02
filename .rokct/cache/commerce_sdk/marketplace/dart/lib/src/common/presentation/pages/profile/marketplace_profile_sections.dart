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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/application/home/home_provider.dart';
import 'package:base_sdk/src/application/language/language_provider.dart';
import 'package:base_sdk/src/application/like/like_provider.dart';
import 'package:base_sdk/src/application/notification/notification_provider.dart';
import 'package:base_sdk/src/application/orders_list/orders_list_provider.dart';
import 'package:base_sdk/src/application/parcels_list/parcel_list_provider.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_profile_footer.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:marketplace_sdk/src/common/presentation/pages/profile/delete_screen.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/profile/help_page.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/profile/reservation_shops.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/profile/widgets/about_page.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/profile/widgets/my_account.dart';

/// marketplace_sdk's sections for base_sdk's generic profile host
/// ([GenericProfilePage] + [ProfileSectionRegistry]).
///
/// Every block of the deprecated customer [ProfilePage] hub is expressed
/// here as a [ProfileSection], preserving the old semantics: the same
/// feature-flag swaps (AppHelpers.getParcel / getReservationEnable /
/// getLendingEnabled, membership), the same navigation targets (the
/// untouched satellite pages, via base_sdk's AppRoutes/EmbeddedWidgets
/// seams), and the same notification-count polling the old page ran. The
/// host owns only the identity header, logout confirmation and ordering.
class MarketplaceProfileSections {
  MarketplaceProfileSections._();

  static const int _base = 100;

  /// The old ProfilePage's `onCardAdded` route param, re-homed: sections
  /// are registered once at boot, so the route shell stores the current
  /// navigation's callback here before building the host page. Null (the
  /// default, and what the boot registration leaves) means no callback —
  /// the same as pushing the old page without the param.
  static Function()? onCardAdded;

  /// Registers every marketplace profile section, mirroring the deprecated
  /// [ProfilePage] body top to bottom.
  static void register() {
    final registry = ProfileSectionRegistry.I;

    // The old identity strip's likes + notifications icon buttons (count
    // badges included) now ride the host's top controls row, between the
    // page title and the host-owned theme toggle / sign-out — the retired
    // 'marketplace.header_actions' section. The notifications action also
    // owns the old page's side effects: the periodic notification-count
    // refresh and the language-change relist.
    registry.registerTopRowAction(
      id: 'marketplace.likes',
      order: 10,
      builder: (context) => const MarketplaceLikesAction(),
    );
    registry.registerTopRowAction(
      id: 'marketplace.notifications',
      order: 20,
      builder: (context) => const MarketplaceNotificationsAction(),
    );

    // The membership card's content moves into the header card, the
    // retired 'marketplace.membership' section: the crown-led plan row
    // ("Plan · <tier> Benefits ›" + expiry) fills the plan slot, and the
    // planBack slot gives the row's tap its in-place card flip (the old
    // card's benefits link only showed ComingSoonDialog — no benefits
    // screen exists — so the back face renders tier + expiry + the
    // member links). Same conditional as the old card: nothing without a
    // stored membership.
    Future<bool> hasMembership() async =>
        LocalStorage.getUser()?.membership != null;
    registry.registerHeaderSlot(
      ProfileHeaderSlot.plan,
      id: 'marketplace.plan',
      visible: hasMembership,
      builder: (context) => const MarketplacePlanRow(),
    );
    registry.registerHeaderSlot(
      ProfileHeaderSlot.planBack,
      id: 'marketplace.plan_back',
      visible: hasMembership,
      builder: (context) => const MarketplacePlanBackCard(),
    );

    // The old identity strip's settings gear, re-homed to the header
    // card's bottom-right corner with its original action: the MyAccount
    // settings hub.
    registry.registerHeaderSlot(
      ProfileHeaderSlot.corner,
      id: 'marketplace.settings',
      builder: (context) => const MarketplaceSettingsCorner(),
    );

    // No 'marketplace.wallet' section any more: the profile wallet card is
    // wallet_sdk's 'wallet.card' section now (registered by wallet_sdk at
    // bootstrap, order 120 — the same slot this SDK's card used to fill).
    // wallet_sdk's card pushes the /wallet-topup route, whose top-up sheet
    // (WalletTopUpScreen) stays marketplace-owned.

    registry.register(ProfileSection(
      id: 'marketplace.tiles',
      order: _base + 30,
      builder: (context) => const MarketplaceProfileTileGrid(),
    ));

    // Registered under base_sdk's default-footer id, not a marketplace
    // id: the host's ensureDefaultSections() fills 'base.footer' with the
    // bare ProfileMetaRow at order 1000 when nothing claimed it, and this
    // bootstrap registration wins the slot (duplicate id = first-wins).
    // Overriding — rather than keeping a separate marketplace.footer and
    // letting the default render too — preserves the old footer's exact
    // layout: links above the meta row, clearance below it.
    registry.register(ProfileSection(
      id: BaseProfileFooter.sectionId,
      order: _base + 40,
      builder: (context) => const MarketplaceProfileFooter(),
    ));
  }
}

/// The liked-shops icon button (count badge), carried over verbatim from
/// the old page's CommonAppBar into the host's top controls row.
class MarketplaceLikesAction extends ConsumerWidget {
  const MarketplaceLikesAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {
        AppRoutes.I.pushLikeRoute(context);
      },
      icon: Badge(
        label: Text(
          (ref.watch(likeProvider).likedShopsCount).toString(),
        ),
        child: Icon(
          Remix.heart_3_line,
          color: AppStyle.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

/// The notifications icon button (count badge) in the host's top controls
/// row. Also owns the old page's side effects: the periodic
/// notification-count timer and the language-change refetch.
class MarketplaceNotificationsAction extends ConsumerStatefulWidget {
  const MarketplaceNotificationsAction({super.key});

  /// Cancels the active notification poll — the old page cancelled its
  /// timer before logout/account deletion so no count fetch fires with a
  /// dead token.
  static void cancelNotificationTimer() =>
      _MarketplaceNotificationsActionState._active?._cancelTimer();

  @override
  ConsumerState<MarketplaceNotificationsAction> createState() =>
      _MarketplaceNotificationsActionState();
}

class _MarketplaceNotificationsActionState
    extends ConsumerState<MarketplaceNotificationsAction> {
  static _MarketplaceNotificationsActionState? _active;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _active = this;
    if (LocalStorage.getToken().isNotEmpty) {
      _timer = Timer.periodic(AppConstants.timeRefresh, (timer) {
        ref.read(notificationProvider.notifier).fetchCount(context);
      });
    }
  }

  void _cancelTimer() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    if (identical(_active, this)) _active = null;
    super.dispose();
  }

  // The old page's post-language-change refetch, verbatim.
  void _getAllInformation() {
    ref.read(homeProvider.notifier)
      ..setAddress()
      ..fetchBanner(context)
      ..fetchAllShops(context)
      ..fetchShopRecommend(context)
      ..fetchShop(context)
      ..fetchStories(context)
      ..fetchNewShops(context)
      ..fetchCategories(context);
    ref.read(shopOrderProvider.notifier).getCart(context, () {});
    ref.read(likeProvider.notifier).fetchLikeShop(context);
    ref.read(profileProvider.notifier).fetchUser(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(languageProvider, (previous, next) {
      if (next.isSuccess && next.isSuccess != previous!.isSuccess) {
        _getAllInformation();
      }
    });

    return IconButton(
      onPressed: () {
        AppRoutes.I.pushNotificationListRoute(context);
      },
      icon: Badge(
        label: Text(
          (ref
                      .watch(notificationProvider)
                      .countOfNotifications
                      ?.notification ??
                  0)
              .toString(),
        ),
        child: Icon(
          Remix.notification_line,
          color: AppStyle.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

/// The membership card's content as the header card's plan-slot row:
/// "Plan · <tier> Benefits ›" + expiry. The host leads the row with the
/// crown glyph and flips the card to [MarketplacePlanBackCard] on tap
/// (the planBack slot is claimed alongside this one). Registered behind a
/// stored-membership gate — the old card's conditional.
class MarketplacePlanRow extends ConsumerWidget {
  const MarketplacePlanRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Same source as the old card, but watching the provider keeps the
    // tier fresh after the host's fetchUser resolves.
    final user =
        ref.watch(profileProvider).userData ?? LocalStorage.getUser();
    final membership = user?.membership;
    final endDate = membership?.endDate ?? '';
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          AppHelpers.getTranslation(TrKeys.plan),
          style: AppStyle.interSemi(size: 13, color: AppStyle.textPrimary),
        ),
        _PlanRowDot(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${membership?.title ?? ''} ${AppHelpers.getTranslation(TrKeys.benefits)}',
              style: AppStyle.interNormal(
                size: 13,
                color: AppStyle.textPrimary,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_sharp,
              size: 16,
              color: AppStyle.textPrimary,
            ),
          ],
        ),
        _PlanRowDot(),
        Text(
          '${AppHelpers.getTranslation(TrKeys.expire)} ${endDate.length >= 10 ? endDate.substring(0, 10) : endDate}',
          style: AppStyle.interNormal(
            size: 11,
            color: AppStyle.textDarkSecondary,
          ),
        ),
      ],
    );
  }
}

class _PlanRowDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: AppStyle.textDarkSecondary,
          shape: BoxShape.circle,
        ),
      );
}

/// The header card's back face for the plan row's in-place flip. No
/// benefits screen exists (the old card's benefits link only showed
/// ComingSoonDialog), so the face renders what membership carries — tier
/// + expiry — plus the member links the footer gates on membership
/// (Help / Terms / Privacy). The host wraps this in the card chrome and
/// flips back on any tap outside the links.
class MarketplacePlanBackCard extends ConsumerWidget {
  const MarketplacePlanBackCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user =
        ref.watch(profileProvider).userData ?? LocalStorage.getUser();
    final membership = user?.membership;
    final endDate = membership?.endDate ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Remix.vip_crown_line,
              size: 16,
              color: AppStyle.primary,
            ),
            8.horizontalSpace,
            Expanded(
              child: Text(
                '${membership?.title ?? ''} ${AppHelpers.getTranslation(TrKeys.benefits)}',
                style: AppStyle.interSemi(
                  size: 16,
                  color: AppStyle.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppStyle.strokeDark, width: 0.5),
            ),
          ),
          child: Text(
            '${AppHelpers.getTranslation(TrKeys.expire)} ${endDate.length >= 10 ? endDate.substring(0, 10) : endDate}',
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ),
        8.verticalSpace,
        Wrap(
          spacing: 4,
          children: [
            _PlanBackLink(
              label: AppHelpers.getTranslation(TrKeys.help),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpPage(),
                  ),
                );
              },
            ),
            _PlanBackLink(
              label: AppHelpers.getTranslation(TrKeys.terms),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmbeddedWidgets.I.termPage(),
                  ),
                );
              },
            ),
            _PlanBackLink(
              label: AppHelpers.getTranslation(TrKeys.privacyPolicy),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmbeddedWidgets.I.policyPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanBackLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PlanBackLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Text(
          label,
          style: AppStyle.interNormal(
            size: 12,
            color: AppStyle.textPrimary,
            textDecoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

/// The old identity strip's settings gear (Remix settings_3_line), pinned
/// to the header card's bottom-right corner with its original action:
/// pushing the MyAccount settings hub.
class MarketplaceSettingsCorner extends StatelessWidget {
  const MarketplaceSettingsCorner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyAccount(isBackButton: false),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Remix.settings_3_line,
          size: 16,
          color: AppStyle.textDarkSecondary,
        ),
      ),
    );
  }
}

/// The icon-tile grid: every square tile of the old hub with its
/// feature-flag swaps (parcel / reservation / membership) and navigation
/// to the untouched satellite pages, row for row.
class MarketplaceProfileTileGrid extends ConsumerStatefulWidget {
  const MarketplaceProfileTileGrid({super.key});

  @override
  ConsumerState<MarketplaceProfileTileGrid> createState() =>
      _MarketplaceProfileTileGridState();
}

class _MarketplaceProfileTileGridState
    extends ConsumerState<MarketplaceProfileTileGrid> {
  @override
  void initState() {
    super.initState();
    // The old page fetched the active order/parcel counts (tile badges) on
    // mount; the identity fetch itself is the host's job now.
    if (LocalStorage.getToken().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ordersListProvider.notifier).fetchActiveOrders(context);
        ref.read(parcelListProvider.notifier).fetchActiveOrders(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = LocalStorage.getAppThemeMode();
    final bool hasMembership = LocalStorage.getUser()?.membership != null;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            (AppHelpers.getParcel())
                ? _buildSquareButton(
                    context,
                    icon: Remix.instance_line,
                    title: AppHelpers.getTranslation(TrKeys.parcels),
                    onTap: () => AppRoutes.I.pushParcelListRoute(context),
                    badgeText: ref
                        .watch(parcelListProvider)
                        .totalActiveCount
                        .toString(),
                  )
                : _buildSquareButton(
                    context,
                    icon: Remix.file_list_3_line,
                    title: AppHelpers.getTranslation(TrKeys.order),
                    onTap: () => AppRoutes.I.pushOrdersListRoute(context),
                    badgeText: ref
                        .watch(ordersListProvider)
                        .totalActiveCount
                        .toString(),
                  ),
            (AppHelpers.getParcel())
                ? _buildSquareButton(
                    context,
                    icon: Remix.file_list_3_line,
                    title: AppHelpers.getTranslation(TrKeys.order),
                    onTap: () => AppRoutes.I.pushOrdersListRoute(context),
                    badgeText: ref
                        .watch(ordersListProvider)
                        .totalActiveCount
                        .toString(),
                  )
                : _buildCardsButton(context, isDarkMode),
            _buildSquareButton(
              context,
              icon: Remix.hand_coin_line,
              title: AppHelpers.getTranslation(TrKeys.inviteFriend),
              onTap: () => AppRoutes.I.pushShareReferralRoute(context),
            ),
          ],
        ),
        10.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSquareButton(
              context,
              icon: Remix.walk_line,
              title: AppHelpers.getTranslation(TrKeys.signUpToDeliver),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmbeddedWidgets.I.becomeDriverPage(),
                ),
              ),
            ),
            _buildSquareButton(
              context,
              icon: Remix.store_fill,
              title: AppHelpers.getTranslation(TrKeys.becomeSeller),
              onTap: () => AppRoutes.I.pushCreateShopRoute(context),
            ),
            _buildSquareButton(
              context,
              icon: Remix.lightbulb_flash_fill,
              iconColor: AppStyle.starColor,
              title: AppHelpers.getTranslation(TrKeys.about),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              ),
            ),
          ],
        ),
        10.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!hasMembership)
              _buildSquareButton(
                context,
                icon: Remix.questionnaire_line,
                title: AppHelpers.getTranslation(TrKeys.help),
                onTap: () => AppRoutes.I.pushHelpRoute(context),
              ),
            if (!hasMembership)
              _buildSquareButton(
                context,
                icon: Remix.contract_fill,
                title: AppHelpers.getTranslation(TrKeys.terms),
                // The old tile cast EmbeddedWidgets.I.termPage() (a Widget)
                // to PageRouteInfo — a guaranteed TypeError on tap. Pushed
                // like the footer's working Terms link instead.
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmbeddedWidgets.I.termPage(),
                  ),
                ),
              ),
            if (!hasMembership)
              _buildSquareButton(
                context,
                icon: Remix.mail_forbid_fill,
                title: AppHelpers.getTranslation(TrKeys.privacyPolicy),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmbeddedWidgets.I.policyPage(),
                  ),
                ),
              ),
          ],
        ),
        10.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppHelpers.getReservationEnable()
                ? _buildSquareButton(
                    context,
                    icon: Remix.reserved_line,
                    title: AppHelpers.getTranslation(TrKeys.reservation),
                    onTap: () {
                      AppHelpers.showAlertDialog(
                        context: context,
                        child: const SizedBox(
                          child: ReservationShops(),
                        ),
                      );
                    },
                  )
                : (AppHelpers.getParcel())
                    ? _buildCardsButton(context, isDarkMode)
                    : _buildSquareButton(
                        context,
                        // Invisible spacer: a transparent border keeps the
                        // slot's footprint without painting an outline in
                        // either mode (a fixed white border glared on dark).
                        borderColor: AppStyle.transparent,
                        backgroundColor: Colors.transparent,
                      ),
            AppHelpers.getReservationEnable()
                ? _buildCardsButton(context, isDarkMode)
                : _buildSquareButton(
                    context,
                    borderColor: AppStyle.transparent,
                    backgroundColor: Colors.transparent,
                  ),
            _buildSquareButton(
              context,
              icon: Remix.logout_box_r_line,
              title: AppHelpers.getTranslation(TrKeys.deleteAccount),
              onTap: () {
                AppHelpers.showAlertDialog(
                  context: context,
                  child: DeleteScreen(
                    isDeleteAccount: true,
                    onDelete:
                        MarketplaceNotificationsAction.cancelNotificationTimer,
                  ),
                );
              },
              // Danger tile: a translucent red tint reads over both the
              // light and dark page surfaces, and AppStyle.red (the
              // palette's only red token) keeps the accent legible in
              // both modes — the old fixed pink[50]/pink[700] pair only
              // worked on light.
              backgroundColor: AppStyle.red.withValues(alpha: 0.15),
              iconColor: AppStyle.red,
              textColor: AppStyle.red,
            ),
          ],
        ),
        10.verticalSpace,
      ],
    );
  }

  /// The Cards tile, appearing in whichever grid slot the parcel /
  /// reservation flags assign it (the old page repeated this block per
  /// slot verbatim).
  Widget _buildCardsButton(BuildContext context, bool isDarkMode) {
    return _buildSquareButton(
      context,
      icon: Remix.bank_card_2_line,
      title: AppHelpers.getTranslation(TrKeys.cards),
      onTap: () {
        AppHelpers.showCustomModalBottomSheet(
          isDismissible: true,
          context: context,
          modal: EmbeddedWidgets.I.paymentScreen(
            tokenizeOnly: true,
            onPaymentComplete: (success) {
              Navigator.pop(context);

              if (success && MarketplaceProfileSections.onCardAdded != null) {
                MarketplaceProfileSections.onCardAdded!();
              }

              if (success) {
                AppHelpers.showCheckTopSnackBarDone(
                  context,
                  AppHelpers.getTranslation(TrKeys.cardAddedSuccessfully),
                );
              } else {
                AppHelpers.showCheckTopSnackBarInfo(
                  context,
                  AppHelpers.getTranslation(TrKeys.paymentRejected),
                );
              }
            },
          ),
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  Widget _buildSquareButton(
    BuildContext context, {
    IconData? icon,
    String? title,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? iconColor,
    Color? textColor,
    Color? borderColor,
    String? badgeText,
    double width = 100,
    double height = 100,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width.w,
        height: height.w,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppStyle.cardDark,
          borderRadius: BorderRadius.circular(20.r),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: [
            if (backgroundColor != Colors.transparent)
              BoxShadow(
                color: AppStyle.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: (icon != null || title != null)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null)
                    Badge(
                      isLabelVisible: badgeText != null,
                      label: Text(badgeText ?? ''),
                      child: Icon(
                        icon,
                        size: 30.r,
                        color: iconColor ?? AppStyle.textPrimary,
                      ),
                    ),
                  if (icon != null && title != null) 8.verticalSpace,
                  if (title != null)
                    Text(
                      title,
                      style: AppStyle.interNormal(
                        size: 14.sp,
                        color: textColor ?? AppStyle.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              )
            : null,
      ),
    );
  }
}

/// The footer: member-only Help/Terms/Privacy text links above base_sdk's
/// shared [ProfileMetaRow] (app name, version, online/offline dot, usage
/// badge) — plus the old page's bottom scroll clearance. Registered under
/// the `base.footer` id so it replaces, rather than duplicates, the
/// host's default footer.
class MarketplaceProfileFooter extends StatelessWidget {
  const MarketplaceProfileFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hasMembership = LocalStorage.getUser()?.membership != null;
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppStyle.transparent,
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasMembership)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppHelpers.getTranslation(TrKeys.help),
                            style: TextStyle(
                              color: AppStyle.textPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.circle_rounded,
                            color: AppStyle.textDarkSecondary,
                            size: 7,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmbeddedWidgets.I.termPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppHelpers.getTranslation(TrKeys.terms),
                            style: TextStyle(
                              color: AppStyle.textPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.circle_rounded,
                            color: AppStyle.textDarkSecondary,
                            size: 7,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EmbeddedWidgets.I.policyPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppHelpers.getTranslation(TrKeys.privacyPolicy),
                            style: TextStyle(
                              color: AppStyle.textPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              // The shared meta row (app name, version, online/offline
              // dot, week+year usage badge) now comes from base_sdk.
              const ProfileMetaRow(),
            ],
          ),
        ),
        // The old page padded the scroll view 120.h at the bottom (the host
        // pads 16); keep the difference clear of the app's bottom overlay.
        SizedBox(height: 104.h),
      ],
    );
  }
}
