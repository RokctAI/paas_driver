import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:${package}/presentation/pages/income/widgets/statistics_item.dart';
import 'package:${package}/presentation/theme/theme.dart';
import 'package:revenue_sdk/src/manager/application/statistics/statistics_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';

class StatisticsSection extends StatelessWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TitleAndIcon(title: AppHelpers.getTranslation(TrKeys.statistics)),
        16.verticalSpace,
        SizedBox(
          height: 190.h,
          child: Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(statisticsProvider);
              return Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      color: AppStyle.white,
                    ),
                    padding: REdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.totalOrders),
                          style: AppStyle.interNormal(
                            size: 12,
                            color: AppStyle.blackColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.countData?.totalCount ?? 0}',
                          style: AppStyle.interSemi(
                            size: 34,
                            color: AppStyle.blackColor,
                            letterSpacing: -1,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: AppHelpers.getTranslation(TrKeys.today),
                            style: AppStyle.interNormal(
                              size: 12,
                              color: AppStyle.blackColor,
                              letterSpacing: -0.3,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    ' ${state.countData?.totalTodayCount ?? 0}',
                                style: AppStyle.interSemi(
                                  size: 12,
                                  color: AppStyle.blackColor,
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
                            title: AppHelpers.getTranslation(
                              TrKeys.acceptedOrders,
                            ),
                            count: state.countData?.totalAcceptedCount ?? 0,
                            percentage: state.countData?.totalCount == 0
                                ? 0
                                : ((state.countData?.totalAcceptedCount ?? 0) /
                                          (state.countData?.totalCount ?? 1)) *
                                      100,
                            bgColor: AppStyle.green,
                            textColor: AppStyle.white,
                            iconColor: AppStyle.white.withOpacity(0.54),
                          ),
                          8.horizontalSpace,
                          StatisticsItem(
                            title: AppHelpers.getTranslation(
                              TrKeys.cancelOrders,
                            ),
                            count: state.countData?.totalCanceledCount ?? 0,
                            percentage: state.countData?.totalCount == 0
                                ? 0
                                : ((state.countData?.totalCanceledCount ?? 0) /
                                          (state.countData?.totalCount ?? 1)) *
                                      100,
                            bgColor: AppStyle.red,
                            textColor: AppStyle.white,
                            iconColor: AppStyle.white.withOpacity(0.54),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatisticsItem(
                            title: AppHelpers.getTranslation(
                              TrKeys.deliveredOrdersCount,
                            ),
                            count: state.countData?.totalDeliveredCount ?? 0,
                            percentage: state.countData?.totalCount == 0
                                ? 0
                                : ((state.countData?.totalDeliveredCount ?? 0) /
                                          (state.countData?.totalCount ?? 1)) *
                                      100,
                            bgColor: AppStyle.white,
                            textColor: AppStyle.blackColor,
                            iconColor: AppStyle.icons,
                          ),
                          8.horizontalSpace,
                          StatisticsItem(
                            title: AppHelpers.getTranslation(TrKeys.newOrders),
                            count: state.countData?.totalNewCount ?? 0,
                            percentage: state.countData?.totalCount == 0
                                ? 0
                                : ((state.countData?.totalNewCount ?? 0) /
                                          (state.countData?.totalCount ?? 1)) *
                                      100,
                            bgColor: AppStyle.white,
                            textColor: AppStyle.blackColor,
                            iconColor: AppStyle.icons,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

