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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:revenue_sdk/src/driver/application/statistics/statistics_notifier.dart';
import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/presentation/components/filter_screen.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class AbbBarScreen extends StatelessWidget {
  // base_sdk's FilterScreen requires an onChangeDay callback (the host copy's
  // calendar sheet fired nothing), so the page passes its notifier in — same
  // wiring as the manager income template's AppbarScreen.
  final StatisticsNotifier event;

  const AbbBarScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
        bottomPadding: 16.h,
        child: GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppHelpers.getTranslation(TrKeys.income),
                    style: AppStyle.interSemi(size: 18),
                  ),
                  Text(
                    AppHelpers.getTranslation(TrKeys.earningsRestaurant),
                    style: AppStyle.interRegular(size: 12, letterSpacing: -0.3),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  AppHelpers.showCustomModalBottomSheet(
                      paddingTop: MediaQuery.paddingOf(context).top,
                      context: context,
                      radius: 12,
                      modal: FilterScreen(
                        isTabBar: false,
                        onChangeDay: (rangeDatePicker) {
                          event.fetchStatistics(
                            startTime: rangeDatePicker.last ?? DateTime.now(),
                            endTime: rangeDatePicker.first ?? DateTime.now(),
                          );
                        },
                      ),
                      isDarkMode: true);
                },
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: const BoxDecoration(
                      color: AppStyle.bgGrey, shape: BoxShape.circle),
                  child: const Icon(
                    Remix.calendar_event_fill,
                    color: AppStyle.blackColor,
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
