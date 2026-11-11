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

import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:delivery_sdk/src/driver/application/order/order_notifier.dart';
import 'package:delivery_sdk/src/driver/application/order/order_provider.dart';
import 'package:delivery_sdk/src/driver/presentation/home/driver_root_nav.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';


import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/component/orders_item.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/presentation/components/custom_tab_bar.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

@RoutePage()
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RefreshController activeController;
  late RefreshController availableController;
  late OrderNotifier event;

  final _tabs = [
    Tab(
      child: Text(
        AppHelpers.getTranslation(TrKeys.activeOrders),
      ),
    ),
    Tab(
      child: Text(
        AppHelpers.getTranslation(TrKeys.availableOrders),
      ),
    ),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    activeController = RefreshController();
    availableController = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier)
        ..fetchActiveOrders(context)
        ..fetchAvailableOrders(context);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(orderProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    activeController.dispose();
    availableController.dispose();
    super.dispose();
  }

  /// Same destinations as the home page's root tab set (CHIP 301): Jobs is
  /// the lit tab here, so a tap on it does nothing; the others open the
  /// existing route for that tab, and Home returns to the root.
  void _openRootTab(DriverRootTab tab) {
    switch (tab) {
      case DriverRootTab.home:
        context.router.popUntilRoot();
      case DriverRootTab.jobs:
        return;
      case DriverRootTab.route:
        context.pushRoute(const DriverRouteRoute());
      case DriverRootTab.income:
        context.pushRoute(const DriverIncomeRoute());
      case DriverRootTab.profile:
        context.pushRoute(const ProfileRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: Stack(
        children: [
          Column(
            children: [
              CustomAppBar(
                bottomPadding: 16.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.orders),
                      style: AppStyle.interSemi(size: 18.sp),
                    ),
                    Row(
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.thereAreOrders),
                          style:
                              AppStyle.interRegular(size: 12.sp, letterSpacing: -0.3),
                        ),
                        Text(
                          " ${state.totalActiveOrder} ",
                          style:
                              AppStyle.interRegular(size: 12.sp, letterSpacing: -0.3),
                        ),
                        Text(
                          AppHelpers.getTranslation(TrKeys.orders).toLowerCase(),
                          style:
                              AppStyle.interRegular(size: 12.sp, letterSpacing: -0.3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              16.verticalSpace,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      CustomTabBar(
                        tabController: _tabController,
                        tabs: _tabs,
                      ),
                      Expanded(
                        child: TabBarView(controller: _tabController, children: [
                          state.isActiveLoading
                              ? const Loading()
                              : SmartRefresher(
                                  enablePullDown: true,
                                  enablePullUp: true,
                                  onRefresh: () {
                                    event.fetchActiveOrdersPage(
                                        context, activeController,
                                        isRefresh: true);
                                  },
                                  onLoading: () {
                                    event.fetchActiveOrdersPage(
                                      context,
                                      activeController,
                                    );
                                  },
                                  controller: activeController,
                                  child: state.activeOrders.isNotEmpty
                                      ? ListView.builder(
                                          padding: EdgeInsets.only(
                                              top: 30.h,
                                              bottom: MediaQuery.of(context)
                                                      .padding
                                                      .bottom +
                                                  42.h),
                                          shrinkWrap: true,
                                          itemCount: state.activeOrders.length,
                                          physics: const BouncingScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            return OrdersItem(
                                              isActiveButton: true,
                                              isOrder: true,
                                              order: state.activeOrders[index],
                                            );
                                          })
                                      : _resultEmpty(),
                                ),
                          state.isAvailableLoading
                              ? const Loading()
                              : SmartRefresher(
                                  enablePullDown: true,
                                  enablePullUp: true,
                                  onRefresh: () {
                                    event.fetchAvailableOrdersPage(
                                        context, availableController,
                                        isRefresh: true);
                                  },
                                  onLoading: () {
                                    event.fetchAvailableOrdersPage(
                                      context,
                                      availableController,
                                    );
                                  },
                                  controller: availableController,
                                  child: state.availableOrders.isNotEmpty
                                      ? ListView.builder(
                                          padding: EdgeInsets.only(
                                              top: 30.h,
                                              bottom: MediaQuery.paddingOf(context)
                                                      .bottom +
                                                  42.h),
                                          shrinkWrap: true,
                                          itemCount: state.availableOrders.length,
                                          physics: const BouncingScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            return OrdersItem(
                                              isOrder: true,
                                              order: state.availableOrders[index],
                                            );
                                          })
                                      : _resultEmpty(),
                                ),
                        ]),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Driver root tab pill: this page is the Jobs tab (Orders), so a
          // tap on Jobs does nothing (see _openRootTab).
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DriverRootNav(
                current: DriverRootTab.jobs,
                onSelect: _openRootTab,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _resultEmpty() {
  return Column(
    children: [
      16.verticalSpace,
      Lottie.asset("assets/lottie/empty-box.json"),
      Text(
        AppHelpers.getTranslation(TrKeys.nothingFound),
        style: AppStyle.interSemi(size: 18.sp),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Text(
          AppHelpers.getTranslation(TrKeys.trySearchingAgain),
          style: AppStyle.interRegular(size: 14.sp),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}
