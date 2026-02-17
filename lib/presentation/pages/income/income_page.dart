import 'package:auto_route/annotations.dart';
import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/application/statistics/statistics_provider.dart';
import 'package:driver/application/statistics/statistics_state.dart';

import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/presentation/component/components.dart';
import 'package:driver/presentation/styles/style.dart';
import 'app_bar_screen.dart';
import 'statistics_screen.dart';
import 'widgets/income_item.dart';

@RoutePage()
class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = [
    Tab(child: Text(AppHelpers.getTranslation(TrKeys.today))),
    Tab(child: Text(AppHelpers.getTranslation(TrKeys.weekly))),
    Tab(child: Text(AppHelpers.getTranslation(TrKeys.monthly))),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        ref
            .read(statisticsProvider.notifier)
            .fetchStatistics(
              startTime: DateTime.now(),
              endTime: DateTime.now(),
            );
      } else if (_tabController.index == 1) {
        ref
            .read(statisticsProvider.notifier)
            .fetchStatistics(
              startTime: DateTime.now(),
              endTime: DateTime.now().subtract(const Duration(days: 7)),
            );
      } else {
        ref
            .read(statisticsProvider.notifier)
            .fetchStatistics(
              startTime: DateTime.now(),
              endTime: DateTime.now().subtract(const Duration(days: 30)),
            );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(statisticsProvider.notifier)
          .fetchStatistics(startTime: DateTime.now(), endTime: DateTime.now());
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticsProvider);
    return Scaffold(
      backgroundColor: Style.greyColor,
      body: Column(
        children: [
          const AbbBarScreen(),
          16.verticalSpace,
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                right: 16.w,
                left: 16.w,
                bottom: MediaQuery.paddingOf(context).bottom + 56.h,
              ),
              child: Column(
                children: [
                  CustomTabBar(tabController: _tabController, tabs: _tabs),
                  24.verticalSpace,
                  _orderPrices(context, state),
                  // TitleAndIcon(
                  //   title: AppHelpers.getTranslation(TrKeys.remittanceIncome),
                  // ),
                  // 12.verticalSpace,
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.servicePrice),
                  //   price: "\$0",
                  // ),
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.tax),
                  //   price: "\$2",
                  // ),
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.shippingCost),
                  //   price: "\$500",
                  // ),
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.adminBenefit),
                  //   price: "\$5.8",
                  // ),
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.yourBenefit),
                  //   price: "\$560",
                  // ),
                  // 24.verticalSpace,
                  TitleAndIcon(
                    title: AppHelpers.getTranslation(
                      TrKeys.deliverymanTransactions,
                    ),
                  ),
                  12.verticalSpace,
                  IncomeItem(
                    title: AppHelpers.getTranslation(TrKeys.wallet),
                    price: AppHelpers.numberFormat(
                      number: LocalStorage.getUser()?.wallet?.price ?? 0,
                    ),
                  ),
                  IncomeItem(
                    title: AppHelpers.getTranslation(TrKeys.rating),
                    price:
                        "${LocalStorage.getUser()?.rate?.toStringAsFixed(1) ?? 0}",
                  ),
                  24.verticalSpace,
                  // TitleAndIcon(
                  //   title: AppHelpers.getTranslation(TrKeys.payment),
                  // ),
                  // 12.verticalSpace,
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.grossProfit),
                  //   price: "\$580",
                  // ),
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.earningsWallet),
                  //   price: "\$100",
                  // ),
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.paid),
                  //   price: "\$0",
                  // ),
                  // IncomeItem(
                  //   title: AppHelpers.getTranslation(TrKeys.paidCourier),
                  //   price: "\$560",
                  //   isBlack: true,
                  // ),
                  // 24.verticalSpace,
                  StatisticsScreen(
                    totalOrders: (state.countData?.data?.totalCount ?? 0)
                        .toString(),
                    todayOrders: (state.countData?.data?.totalTodayCount ?? 0)
                        .toString(),
                    acceptedOrders:
                        (state.countData?.data?.totalAcceptedCount ?? 0)
                            .toString(),
                    rejectedOrders:
                        (state.countData?.data?.totalCanceledCount ?? 0)
                            .toString(),
                    doneOrders:
                        (state.countData?.data?.totalDeliveredCount ?? 0)
                            .toString(),
                    canceledOrders: (state.countData?.data?.totalNewCount ?? 0)
                        .toString(),
                    acceptedPer:
                        "${((state.countData?.data?.totalAcceptedCount ?? 0) / (state.countData?.data?.totalCount ?? 1) * 100).toStringAsFixed(1)}%",
                    rejectedPer:
                        "${((state.countData?.data?.totalCanceledCount ?? 0) / (state.countData?.data?.totalCount ?? 1) * 100).toStringAsFixed(1)}%",
                    donePer:
                        "${((state.countData?.data?.totalDeliveredCount ?? 0) / (state.countData?.data?.totalCount ?? 1) * 100).toStringAsFixed(1)}%",
                    canceledPer:
                        "${((state.countData?.data?.totalNewCount ?? 0) / (state.countData?.data?.totalCount ?? 1) * 100).toStringAsFixed(1)}%",
                  ),
                  32.verticalSpace,
                  _chart(state),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: const PopButton(),
    );
  }

  Column _chart(StatisticsState state) {
    return Column(
      children: [
        TitleAndIcon(title: AppHelpers.getTranslation(TrKeys.earningsChart)),
        16.verticalSpace,
        Container(
          width: double.infinity,
          height: 300.h,
          decoration: BoxDecoration(
            color: Style.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.all(16.r),
          child: BarChart(
            state.list,
            animate: true,
            vertical: false,
            animationDuration: const Duration(seconds: 1),
            defaultRenderer: BarRendererConfig(
              cornerStrategy: const ConstCornerStrategy(6),
            ),
          ),
        ),
        32.verticalSpace,
      ],
    );
  }

  Column _orderPrices(BuildContext context, StatisticsState state) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Style.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.orderPrice),
                style: Style.interNormal(
                  size: 14.sp,
                  color: Style.black,
                  letterSpacing: -0.3,
                ),
              ),
              16.verticalSpace,
              Text(
                AppHelpers.numberFormat(
                  number: state.countData?.data?.lastOrderTotalPrice ?? 0,
                ),
                style: Style.interSemi(
                  size: 32.sp,
                  color: Style.black,
                  letterSpacing: -0.3,
                ),
              ),
              4.verticalSpace,
              RichText(
                text: TextSpan(
                  text: AppHelpers.getTranslation(TrKeys.lastIncome),
                  style: Style.interNormal(
                    size: 12.sp,
                    color: Style.black,
                    letterSpacing: -0.3,
                  ),
                  children: [
                    TextSpan(
                      text: AppHelpers.numberFormat(
                        number: state.countData?.data?.lastOrderIncome ?? 0,
                      ),
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
        // 10.verticalSpace,
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Container(
        //       width: (MediaQuery.sizeOf(context).width - 40) / 2,
        //       decoration: BoxDecoration(
        //         color: Style.blackColor,
        //         borderRadius: BorderRadius.circular(10.r),
        //       ),
        //       padding: EdgeInsets.all(16.r),
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Text(
        //             AppHelpers.getTranslation(TrKeys.restaurantRevenue),
        //             style: Style.interNormal(
        //                 size: 12.sp, color: Style.white, letterSpacing: -0.3),
        //           ),
        //           Text(
        //             "\$79",
        //             style: Style.interSemi(
        //                 size: 22.sp, color: Style.white, letterSpacing: -0.3),
        //           )
        //         ],
        //       ),
        //     ),
        //     Container(
        //       width: (MediaQuery.sizeOf(context).width - 40) / 2,
        //       decoration: BoxDecoration(
        //         color: Style.blackColor,
        //         borderRadius: BorderRadius.circular(10.r),
        //       ),
        //       padding: EdgeInsets.all(16.r),
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: [
        //           Text(
        //             AppHelpers.getTranslation(TrKeys.fMRevenue),
        //             style: Style.interNormal(
        //                 size: 12.sp, color: Style.white, letterSpacing: -0.3),
        //           ),
        //           Text(
        //             "\$7",
        //             style: Style.interSemi(
        //                 size: 22.sp, color: Style.white, letterSpacing: -0.3),
        //           )
        //         ],
        //       ),
        //     )
        //   ],
        // ),
        32.verticalSpace,
      ],
    );
  }
}
