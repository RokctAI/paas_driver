// Copyright (c) 2026 RokctAI
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
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/application/orders_list/orders_list_notifier.dart';
import 'package:base_sdk/src/application/orders_list/orders_list_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/custom_tab_bar.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/widgets/orders_item.dart';
import 'package:base_sdk/src/presentation/components/badges.dart';

@RoutePage()
class OrdersListPage extends ConsumerStatefulWidget {
  const OrdersListPage({super.key});

  @override
  ConsumerState<OrdersListPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrdersListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late RefreshController activeRefreshController;
  late RefreshController historyRefreshController;
  late RefreshController refundRefreshController;
  late OrdersListNotifier event;

  final _tabs = [
    Tab(text: AppHelpers.getTranslation(TrKeys.activeOrders)),
    Tab(text: AppHelpers.getTranslation(TrKeys.orderHistory)),
    Tab(text: AppHelpers.getTranslation(TrKeys.reFound)),
  ];

  @override
  void initState() {
    activeRefreshController = RefreshController();
    historyRefreshController = RefreshController();
    refundRefreshController = RefreshController();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersListProvider.notifier).fetchActiveOrders(context);
      ref.read(ordersListProvider.notifier).fetchHistoryOrders(context);
      ref.read(ordersListProvider.notifier).fetchRefundOrders(context);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(ordersListProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    activeRefreshController.dispose();
    historyRefreshController.dispose();
    refundRefreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = LocalStorage.getAppThemeMode();
    final bool isLtr = LocalStorage.getLangLtr();
    final state = ref.watch(ordersListProvider);
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppStyle.mainBackDark : AppStyle.bgGrey,
        body: Column(
          children: [
            CommonAppBar(
              child: Text(
                AppHelpers.getTranslation(TrKeys.order),
                style: AppStyle.interNoSemi(size: 18, color: AppStyle.black),
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    CustomTabBar(
                      isScrollable: true,
                      tabController: _tabController,
                      tabs: _tabs,
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          state.isActiveLoading
                              ? const Loading()
                              : SmartRefresher(
                                  controller: activeRefreshController,
                                  enablePullDown: true,
                                  enablePullUp: true,
                                  onRefresh: () {
                                    event.fetchActiveOrdersPage(
                                      context,
                                      activeRefreshController,
                                      isRefresh: true,
                                    );
                                    activeRefreshController.refreshCompleted();
                                  },
                                  onLoading: () {
                                    event.fetchActiveOrdersPage(
                                      context,
                                      activeRefreshController,
                                    );
                                  },
                                  child: state.activeOrders.isNotEmpty
                                      ? ListView.builder(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.only(top: 24.h),
                                          itemCount: state.activeOrders.length,
                                          itemBuilder: (context, index) {
                                            return OrdersItem(
                                              order: state.activeOrders[index],
                                              isActive: true,
                                            );
                                          },
                                        )
                                      : _resultEmpty(),
                                ),
                          state.isHistoryLoading
                              ? const Loading()
                              : SmartRefresher(
                                  controller: historyRefreshController,
                                  enablePullDown: true,
                                  enablePullUp: true,
                                  onRefresh: () {
                                    event.fetchHistoryOrdersPage(
                                      context,
                                      historyRefreshController,
                                      isRefresh: true,
                                    );
                                    historyRefreshController.refreshCompleted();
                                  },
                                  onLoading: () {
                                    event.fetchHistoryOrdersPage(
                                      context,
                                      historyRefreshController,
                                    );
                                  },
                                  child: ListView.builder(
                                    padding: EdgeInsets.only(top: 24.h),
                                    itemCount: state.historyOrders.length,
                                    itemBuilder: (context, index) {
                                      return OrdersItem(
                                        order: state.historyOrders[index],
                                        isActive: false,
                                      );
                                    },
                                  ),
                                ),
                          state.isRefundLoading
                              ? const Loading()
                              : SmartRefresher(
                                  controller: refundRefreshController,
                                  enablePullDown: true,
                                  enablePullUp: true,
                                  onRefresh: () {
                                    event.fetchRefundOrdersPage(
                                      context,
                                      refundRefreshController,
                                      isRefresh: true,
                                    );
                                    refundRefreshController.refreshCompleted();
                                  },
                                  onLoading: () {
                                    event.fetchRefundOrdersPage(
                                      context,
                                      refundRefreshController,
                                    );
                                  },
                                  child: ListView.builder(
                                    padding: EdgeInsets.only(top: 24.h),
                                    itemCount: state.refundOrders.length,
                                    itemBuilder: (context, index) {
                                      return OrdersItem(
                                        isRefund: true,
                                        isActive: false,
                                        refund: state.refundOrders[index],
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: const PopButton(),
        ),
      ),
    );
  }
}

Widget _resultEmpty() {
  return EmptyBadge(
    subtitleText: "Your Orders will appear here",
    titleText: "No Orders",
  );
}
