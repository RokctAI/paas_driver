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


import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
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
          body: Column(
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PopButton(),
                // !state.isChangeTabBar
                //     ? Expanded(
                //         child: Padding(
                //           padding: EdgeInsets.only(left: 10.w),
                //           child: CustomButton(
                //             background: Style.brandGreen,
                //             textColor: Style.black,
                //             title: AppHelpers.getTranslation(TrKeys.addNewCart),
                //             onPressed: () {
                //               AppHelpers.showCustomModalBottomSheet(
                //                 paddingTop: MediaQuery.paddingOf(context).top,
                //                 context: context,
                //                 modal: const AddToScreen(),
                //                 isDarkMode: isDarkMode,
                //               );
                //             },
                //           ),
                //         ),
                //       )
                //     :
                SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
