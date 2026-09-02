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


import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:remixicon/remixicon.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

import 'package:comms_sdk/src/common/presentation/pages/setting/notification_page.dart';

@RoutePage()
class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage>
    with SingleTickerProviderStateMixin {
  // late TabController _tabController;
  late bool isDarkMode;
  late bool isLtr;

  // final _tabs = [
  //   const Tab(text: 'Payment'),
  //   const Tab(text: 'Notification'),
  // ];

  @override
  void initState() {
    // _tabController = TabController(length: 2, vsync: this);
    // _tabController.addListener(() {
    //   ref.read(settingProvider.notifier).changeIndex(_tabController.index.isOdd);
    // });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    isDarkMode = LocalStorage.getAppThemeMode();
    isLtr = LocalStorage.getLangLtr();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: isDarkMode ? AppStyle.mainBackDark : AppStyle.bgGrey,
          body: Stack(
            children: [
              Column(
                children: [
                  CommonAppBar(
                    child: Text(
                      AppHelpers.getTranslation(TrKeys.notification),
                      style: AppStyle.interNoSemi(size: 18, color: AppStyle.black),
                    ),
                  ),
                  16.verticalSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: const NotificationPage(),
                    // Column(
                    //   children: [
                    //     CustomTabBar(
                    //       tabController: _tabController,
                    //       tabs: _tabs,
                    //     ),
                    //     SizedBox(
                    //       height: MediaQuery.sizeOf(context).height - 180.h,
                    //       child: TabBarView(controller: _tabController, children: [
                    //         Column(
                    //           children: [
                    //             24.verticalSpace,
                    //             const CardWidget(
                    //               number: "8278 3100 2002 6576",
                    //               startDate: "09 / 25",
                    //               name: "ANTONIO BANDERO",
                    //             ),
                    //           ],
                    //         ),
                    //         const NotificationPage()
                    //       ]),
                    //     )
                    //   ],
                    // ),
                  ),
                ],
              ),
              // The floating nav's back-only pill (FloatingNavBack, core#125 — design
              // strip section 12's one-back rule): the shared pill housing carrying
              // only the leading back segment, this screen's ONE back affordance,
              // replacing the standalone PopButton. Back-only (empty tab list)
              // because the host app's root tabs are not reachable from this SDK
              // package's pushed route.
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FloatingBottomNav(
                    mode: FloatingNavTabsMode(
                      tabs: const [],
                      currentIndex: 0,
                      onSelect: (_) {},
                      back: FloatingNavBack(
                        icon: Remix.arrow_left_wide_fill,
                        label: AppHelpers.getTranslation(TrKeys.back),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
