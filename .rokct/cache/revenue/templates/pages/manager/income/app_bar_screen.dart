import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:revenue_sdk/src/manager/application/statistics/statistics_notifier.dart';
import 'package:${package}/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class AppbarScreen extends StatelessWidget {
  final StatisticsNotifier event;

  const AppbarScreen({super.key, required this.event});

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
                  isDarkMode: true,
                );
              },
              child: Container(
                padding: EdgeInsets.all(10.r),
                decoration: const BoxDecoration(
                  color: AppStyle.textGrey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Remix.calendar_event_fill,
                  color: AppStyle.blackColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

