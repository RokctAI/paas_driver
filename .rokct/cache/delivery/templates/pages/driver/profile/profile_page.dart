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


// Host route shell for the driver profile: base_sdk's generic profile host
// (design strip section 1 - the unified header, top row and two-plane
// spread on EVERY profile page) carrying delivery_sdk's driver sections,
// in place of the retired standalone page this file used to be.
//
// Route name (ProfileRoute, /profile) and the parameterless constructor are
// unchanged, so the home page's avatar and Profile tab, users_sdk's tour
// fragment and the zones/revenue chapters that follow it keep resolving.
// The page is auto_route-scanned host code (installed into the composed
// app), which is what lets it name the composed app's generated routes
// for the row destinations and hand them to the SDK-resident sections as
// callbacks - the same split as merchants' restaurant_page.dart and
// marketplace's route shell.
//
// Two-state nav (approved 12d): the profile is a PUSHED page (chip 347's
// one-back rule - the driver app has no root tab set on pushed pages), so
// it carries the bare back pill: bottom-centre on a phone, as every other
// driver page draws it, and at the bottom-END corner on plane widths, where
// PlaneHost parks its own pill.
//
// Plane widths are base_sdk's GenericProfileRoutePage (1.60.10) rather than
// a PlaneHost of this file's own: it is the host that provides the
// ProfileSectionNavigator seam, opens a section's detail in the DETAIL
// PLANE, seeds the registry's default section into the third plane on a
// three-plane screen (tablet audit 2026-09-07, 16-users_profile: the
// driver profile left that plane empty) and draws the same bottom-END
// corner pill this shell drew - the pill pops an opened detail first and
// the route after. The phone branch is untouched.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:${package}/presentation/pages/order_history/order_history.dart';
import 'package:${package}/presentation/pages/profile/courier_statistics_provider.dart';
import 'package:${package}/presentation/pages/profile/widgets/edit_profile_modal.dart';
import 'package:${package}/presentation/pages/profile/widgets/logout_modal.dart';
import 'package:${package}/presentation/routes/app_router.dart';

import 'package:base_sdk/src/application/app_widget/app_provider.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_route_page.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section.dart';
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/application/home/home_provider.dart';
import 'package:delivery_sdk/src/driver/presentation/profile/driver_profile_sections.dart';

/// Registers the driver's profile content with base_sdk's
/// [ProfileSectionRegistry]: the header pencil and top-row sign-out, the
/// stats slot, and delivery_sdk's row / helper sections. Idempotent - the
/// page calls it every time it mounts and the registry keeps the first
/// registration.
void registerDriverProfileSections() {
  final registry = ProfileSectionRegistry.I;

  // Header pencil (chip 109): the same Profile settings sheet the row
  // opens - users_sdk's tour taps the row by its title, so both stay.
  registry.onEditProfile ??= _openProfileSettings;

  // Top-row sign-out (chip 76): the host runs its own confirmation, so
  // this is the confirmed branch of the old LogoutModal, verbatim.
  registry.onLogout ??= _signOut;

  if (!registry.containsHeaderSlot(ProfileHeaderSlot.stats)) {
    registry.registerHeaderSlot(
      ProfileHeaderSlot.stats,
      id: DriverProfileSections.statsSlotId,
      builder: (context) => const _DriverStatsSlot(),
    );
  }

  // Hidden in demo builds, as the old page hid it.
  final void Function(BuildContext context)? onDeleteAccount =
      AppConstants.isDemo ? null : _openDeleteAccount;

  DriverProfileSections.register(
    actions: DriverProfileActions(
      onProfileSettings: _openProfileSettings,
      onDeliveryZone: _openDeliveryZone,
      onOrders: _openOrders,
      onParcels: _openParcels,
      onNotifications: _openNotifications,
      onOrderHistory: _openOrderHistory,
      onParcelHistory: _openParcelHistory,
      onIncome: _openIncome,
      onLanguage: _openLanguage,
      onDeleteAccount: onDeleteAccount,
      onOnlineHelper: _callOnlineHelper,
      // The rows section's detail for the plane host (base_sdk 1.60.10):
      // the Order history list, embedded - the same content _openOrderHistory
      // pushes, without the route's Scaffold, app bar, pill or filter.
      // The host seeds it into the third plane on a three-plane screen.
      orderHistoryDetail: (context) => const OrderHistoryPane(heading: true),
    ),
  );
}

void _openProfileSettings(BuildContext context) {
  AppHelpers.showCustomModalBottomSheet(
    paddingTop: MediaQuery.paddingOf(context).top + 32.h,
    context: context,
    modal: const EditProfileModal(),
    isDarkMode: LocalStorage.getAppThemeMode(),
  );
}

void _signOut(BuildContext context) {
  final GoogleSignIn signIn = GoogleSignIn();
  signIn.disconnect();
  signIn.signOut();
  LocalStorage.logout();
  context.router.popUntilRoot();
  context.replaceRoute(const LoginRoute());
}

Future<void> _openDeliveryZone(BuildContext context) async {
  await context.pushRoute(const DriverDeliveryZoneRoute());
  if (!context.mounted) return;
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(homeProvider.notifier).fetchDeliveryZone(isFetch: true);
}

void _openOrders(BuildContext context) {
  context.pushRoute(const OrdersRoute());
}

void _openParcels(BuildContext context) {
  context.pushRoute(const ParcelsRoute());
}

void _openNotifications(BuildContext context) {
  context.pushRoute(const NotificationListRoute());
}

void _openOrderHistory(BuildContext context) {
  context.pushRoute(const OrderHistoryRoute());
}

void _openParcelHistory(BuildContext context) {
  context.pushRoute(const ParcelHistoryRoute());
}

void _openIncome(BuildContext context) {
  context.pushRoute(const DriverIncomeRoute());
}

void _openLanguage(BuildContext context) {
  AppHelpers.showCustomModalBottomSheet(
    isDismissible: true,
    isDrag: false,
    context: context,
    modal: EmbeddedWidgets.I.languageScreen(
      onSave: () {
        Navigator.pop(context);
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(appProvider.notifier).changeLocale(LocalStorage.getLanguage());
      },
    ),
    isDarkMode: LocalStorage.getAppThemeMode(),
  );
}

void _openDeleteAccount(BuildContext context) {
  AppHelpers.showCustomModalBottomSheet(
    context: context,
    modal: const LogoutModal(isDeleteAccount: true),
    isDarkMode: LocalStorage.getAppThemeMode(),
  );
}

Future<void> _callOnlineHelper(BuildContext context) async {
  final Uri launchUri = Uri(scheme: 'tel', path: AppHelpers.getAppPhone());
  await launchUrl(launchUri);
}

/// The header card's stats row: wallet balance from the host's profile
/// state (the session user until it hydrates), last profit and delivered
/// count from the courier statistics the home page fetched.
class _DriverStatsSlot extends ConsumerWidget {
  const _DriverStatsSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).userData ?? LocalStorage.getUser();
    final statistics =
        ref.watch(courierProfileStatisticsProvider).statistics?.data;
    return DriverProfileStatsRow(
      balance: user?.wallet?.price,
      lastProfit: statistics?.totalPrice,
      deliveredOrders: statistics?.deliveredOrdersCount ?? 0,
    );
  }
}

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final bool isLtr = LocalStorage.getLangLtr();

  @override
  void initState() {
    super.initState();
    // Before the host's first build: GenericProfilePage reads the registry
    // and resolves its gates in its own initState.
    registerDriverProfileSections();
  }

  @override
  Widget build(BuildContext context) {
    final back = FloatingNavBack(
      icon: Remix.arrow_left_wide_fill,
      label: AppHelpers.getTranslation(TrKeys.back),
    );
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide = PlaneHost.planeCountFor(constraints.maxWidth) > 1;
          if (wide) {
            // The universal profile cap (approved 4c) - two planes at
            // most - plus the detail plane and its default, and the
            // corner pill, all owned by base's routed host.
            return const GenericProfileRoutePage();
          }
          return Stack(
            children: [
              Positioned.fill(
                child: PlaneHost(
                  stack: [
                    PlanePage(
                      name: 'driver-profile',
                      span: PlaneSpan.two,
                      builder: (context) => const GenericProfilePage(),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FloatingBottomNav(
                    mode: FloatingNavTabsMode(
                      tabs: const [],
                      currentIndex: 0,
                      onSelect: (_) {},
                      back: back,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
