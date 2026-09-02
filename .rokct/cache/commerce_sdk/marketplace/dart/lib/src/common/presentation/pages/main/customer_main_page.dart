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
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/application/main/main_provider.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/pages/profile/generic_profile_page.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import '../home/home_four/home_page_four.dart';
import '../home/home_zero/home_page.dart';
import '../like/like_page.dart';
import '../search/search_page.dart';

/// The customer app's main destination — marketplace_sdk is the customer
/// home SDK, so it owns the surface `AppHelpers.goHome()` lands on
/// (`AppRoutes.replaceMainRoute`, declared in this SDK's manifest the same
/// way merchants_sdk owns the manager `/main`).
///
/// Until this landed the customer compose had NO main route at all — the
/// route table carried only the auth/initial/profile shells — so every
/// goHome() call (post-login, post-registration, guest Skip) threw
/// `_HostAppRoutes`' noSuchMethod StateError and the user was stranded on
/// whatever screen was up (after registering: the registration-steps
/// shell's one-frame spinner, which is exactly the endless "loading icon
/// instead of the home shimmers" report this page fixes — with a real home
/// to land on, the home page's own shimmer placeholders show while its
/// content loads).
///
/// Deliberately lean (the full legacy paas_customer shell — parcel, wallet
/// history, service tabs, per-ui-type navigators — is being migrated
/// separately): four tabs over the surfaces marketplace_sdk owns today.
/// Home follows the backend `ui_type` setting the way the legacy shell did
/// for the two variants this SDK kept (home_zero default, home_four for
/// type 4); the retired one/two/three variants fall back to home_zero.
/// Tabs are lazy (preload only Home) so the search/like/profile providers
/// don't all fetch at boot.
class CustomerMainPage extends ConsumerWidget {
  const CustomerMainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedIndex = ref.watch(
      mainProvider.select((state) => state.selectIndex),
    );
    return KeyboardDismisser(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: ProsteIndexedStack(
          index: selectedIndex,
          children: [
            IndexedStackChild(
              child: AppHelpers.getType() == 4
                  ? const HomePageFour()
                  : const HomePage(),
              preload: true,
            ),
            IndexedStackChild(child: const SearchPage(isBackButton: false)),
            IndexedStackChild(child: const LikePage(isBackButton: false)),
            IndexedStackChild(child: const GenericProfilePage()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) =>
              ref.read(mainProvider.notifier).selectIndex(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppStyle.bottomNavigationBarColor,
          selectedItemColor: AppStyle.primary,
          unselectedItemColor: AppStyle.textDarkSecondary,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Remix.home_5_line),
              label: AppHelpers.getTranslation(TrKeys.home),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Remix.search_2_line),
              label: AppHelpers.getTranslation(TrKeys.search),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Remix.heart_3_line),
              label: AppHelpers.getTranslation(TrKeys.liked),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Remix.user_line),
              label: AppHelpers.getTranslation(TrKeys.profile),
            ),
          ],
        ),
      ),
    );
  }
}
