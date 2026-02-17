import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/styles/style.dart';
import 'widgets/statistics_item.dart';

class StatisticsScreen extends StatelessWidget {
  final String totalOrders;
  final String todayOrders;
  final String acceptedOrders;
  final String rejectedOrders;
  final String doneOrders;
  final String canceledOrders;
  final String acceptedPer;
  final String rejectedPer;
  final String donePer;
  final String canceledPer;

  const StatisticsScreen({
    super.key,
    required this.totalOrders,
    required this.todayOrders,
    required this.acceptedOrders,
    required this.rejectedOrders,
    required this.doneOrders,
    required this.canceledOrders,
    required this.acceptedPer,
    required this.rejectedPer,
    required this.donePer,
    required this.canceledPer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleAndIcon(title: AppHelpers.getTranslation(TrKeys.statistics)),
        16.verticalSpace,
        SizedBox(
          height: 190.h,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: Style.white,
                ),
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.totalOrders),
                      style: Style.interNormal(
                        size: 12.sp,
                        color: Style.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      totalOrders,
                      style: Style.interSemi(
                        size: 34.sp,
                        color: Style.black,
                        letterSpacing: -1,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: AppHelpers.getTranslation(TrKeys.today),
                        style: Style.interNormal(
                          size: 12.sp,
                          color: Style.black,
                          letterSpacing: -0.3,
                        ),
                        children: [
                          TextSpan(
                            text: " $todayOrders",
                            style: Style.interSemi(
                              size: 12.sp,
                              color: Style.black,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      StatisticsItem(
                        title: AppHelpers.getTranslation(TrKeys.acceptedOrders),
                        count: acceptedOrders,
                        percentage: acceptedPer == "NaN%" ? "0%" : acceptedPer,
                        bgColor: Style.greenColor,
                        textColor: Style.white,
                        iconColor: Style.white.withValues(alpha: 0.54),
                      ),
                      8.horizontalSpace,
                      StatisticsItem(
                        title: AppHelpers.getTranslation(TrKeys.rejectedOrders),
                        count: rejectedOrders,
                        percentage: rejectedPer == "NaN%" ? "0%" : rejectedPer,
                        bgColor: Style.redColor,
                        textColor: Style.white,
                        iconColor: Style.white.withValues(alpha: 0.54),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatisticsItem(
                        title: AppHelpers.getTranslation(TrKeys.doneOrders),
                        count: doneOrders,
                        percentage: donePer == "NaN%" ? "0%" : donePer,
                        bgColor: Style.white,
                        textColor: Style.black,
                        iconColor: Style.iconColor,
                      ),
                      8.horizontalSpace,
                      StatisticsItem(
                        title: AppHelpers.getTranslation(TrKeys.newOrders),
                        count: canceledOrders,
                        percentage: canceledPer == "NaN%" ? "0%" : canceledPer,
                        bgColor: Style.white,
                        textColor: Style.black,
                        iconColor: Style.iconColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
