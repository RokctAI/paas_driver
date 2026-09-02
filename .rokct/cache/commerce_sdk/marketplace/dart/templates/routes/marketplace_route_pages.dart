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


// ignore_for_file: unused_result

// Host-side route shell + profile-host wiring for marketplace_sdk.
//
// auto_route's generator only scans the host package, so the SDK-resident
// profile host is wrapped in a thin @RoutePage shell here (the same pattern
// as base_sdk's route_pages.dart and lms_sdk's lms_route_pages.dart).
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart'
    as pages;
import 'package:base_sdk/src/presentation/pages/profile/profile_section_registry.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/main/customer_main_page.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/profile/marketplace_profile_sections.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/profile/widgets/my_account.dart';

/// Registers every marketplace profile section with base_sdk's
/// [ProfileSectionRegistry] — called once at boot from this SDK's
/// `di_hooks` manifest entry. Everything routes through base_sdk seams
/// (AppRoutes / EmbeddedWidgets), so no generated route class is needed
/// here beyond the shell below.
void registerMarketplaceProfileSections() {
  // Header edit affordance (the in-card pencil): MyAccount is the settings
  // hub that carries Edit account (plus password/addresses/notifications/
  // language/currency) — the mapping that shipped with the host adoption.
  // The old identity-strip settings gear itself is back as the header
  // card's corner slot with the same MyAccount action (see
  // MarketplaceSettingsCorner in marketplace_profile_sections.dart).
  ProfileSectionRegistry.I.onEditProfile = (context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyAccount(isBackButton: false),
      ),
    );
  };

  // Top-row sign-out affordance — the confirmed branch of the old page's
  // DeleteScreen dialog, verbatim; the host page already ran its own
  // logout confirmation, so no second dialog.
  ProfileSectionRegistry.I.onLogout = (context) {
    MarketplaceNotificationsAction.cancelNotificationTimer();
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(profileProvider.notifier).logOut();
    container.refresh(shopOrderProvider);
    container.refresh(profileProvider);
    context.router.popUntilRoot();
    AppRoutes.I.replaceLoginRoute(context);
  };

  MarketplaceProfileSections.register();
}

/// Host route shell for the customer profile, now rendering base_sdk's
/// generic profile host. Route name (ProfileRoute) and constructor params
/// match the deprecated marketplace ProfilePage, so existing navigation
/// call-sites keep working; the sections come from
/// [registerMarketplaceProfileSections].
@RoutePage(name: 'ProfileRoute')
class ProfileRouteView extends StatelessWidget {
  final bool isBackButton;
  final Function()? onCardAdded;

  const ProfileRouteView({
    super.key,
    this.onCardAdded,
    this.isBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // Sections are registered at boot; the per-navigation card-added
    // callback rides this slot instead of a constructor param.
    MarketplaceProfileSections.onCardAdded = onCardAdded;
    return Stack(
      children: [
        const pages.GenericProfilePage(),
        // The old page's floating back button (FAB startFloat + 16.w pad).
        if (isBackButton)
          Positioned(
            left: 32.w,
            bottom: 16.h,
            child: const SafeArea(child: PopButton()),
          ),
      ],
    );
  }
}

/// Host route shell for the customer app's main destination (the customer
/// twin of merchants_sdk's manager MainRoute): marketplace_sdk is the
/// customer home SDK, so it owns the surface `AppHelpers.goHome()` lands
/// on. Declared as `/main` + `replaceMainRoute` in this SDK's manifest —
/// before this shell the customer compose had no main route at all, and
/// every post-login / post-registration / guest-skip goHome() threw
/// _HostAppRoutes' noSuchMethod StateError, stranding the user (after
/// registering: on the registration-steps shell's spinner).
@RoutePage(name: 'MainRoute')
class MainRouteView extends StatelessWidget {
  const MainRouteView({super.key});

  @override
  Widget build(BuildContext context) => const CustomerMainPage();
}
