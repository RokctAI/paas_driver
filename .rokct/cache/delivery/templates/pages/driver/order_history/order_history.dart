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
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:delivery_sdk/src/driver/application/order/order_provider.dart';

import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/component/filter_screen.dart';
import 'package:${package}/presentation/component/orders_item.dart';
import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

@RoutePage()
class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: Stack(
        children: [
          Column(
            children: [
              CustomAppBar(
                bottomPadding: 16.h,
                child: const _OrderHistoryHeading(),
              ),
              // The list itself, shared with the driver profile's detail
              // plane (OrderHistoryPane below).
              const Expanded(child: OrderHistoryPane()),
            ],
          ),
          // The floating nav's back-only pill (FloatingNavBack, core#125 — design
          // strip section 12's one-back rule): the shared pill housing carrying
          // only the leading back segment, this screen's ONE back affordance,
          // replacing the standalone PopButton. Back-only (empty tab list): the
          // driver app composes no root tab set.
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
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        // The back affordance moved into the floating nav's pill (see the
        // body Stack); only the filter action remains here, keeping its
        // right-edge spot.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                AppHelpers.showCustomModalBottomSheet(
                  paddingTop: MediaQuery.paddingOf(context).top,
                  context: context,
                  radius: 12,
                  modal: const FilterScreen(),
                  isDarkMode: true,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppStyle.primary,
                ),
                padding: EdgeInsets.all(16.r),
                child: const Icon(Remix.equalizer_fill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The page's title and subtitle - inside the app bar on the routed page,
/// as a plain heading at the top of the embedded pane.
class _OrderHistoryHeading extends StatelessWidget {
  const _OrderHistoryHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          AppHelpers.getTranslation(TrKeys.orderHistory),
          style: AppStyle.interSemi(size: 18.sp),
        ),
        Text(
          AppHelpers.getTranslation(TrKeys.thereAreOrders),
          style: AppStyle.interRegular(
            size: 12.sp,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// The order-history CONTENT: the fetch on mount, the loading state and the
/// pull-to-refresh / load-more list of delivered orders - everything the
/// routed page shows below its app bar, with no Scaffold, app bar, back
/// pill or filter of its own.
///
/// Two hosts: [OrderHistoryPage] above (the phone route and every push of
/// the Order history row), and the driver profile's DETAIL PLANE - base_sdk
/// 1.60.10's [ProfileSection.detailBuilder], which the installed
/// profile_page.dart shell hands to delivery_sdk's rows section so the
/// tablet profile lands with its third plane showing this list (tablet
/// audit 2026-09-07, 16-users_profile). With [heading] the pane leads with
/// the page's own title and subtitle as plain text, since the plane it is
/// embedded in has no app bar to carry them.
class OrderHistoryPane extends ConsumerStatefulWidget {
  const OrderHistoryPane({super.key, this.heading = false});

  /// Lead with the title and subtitle the routed page's app bar carries.
  final bool heading;

  @override
  ConsumerState<OrderHistoryPane> createState() => _OrderHistoryPaneState();
}

class _OrderHistoryPaneState extends ConsumerState<OrderHistoryPane> {
  late RefreshController historyController;

  @override
  void initState() {
    historyController = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(orderProvider.notifier).fetchHistoryOrders(context);
    });
    super.initState();
  }

  @override
  void dispose() {
    historyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final Widget list = state.isHistoryLoading
        ? const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Loading(),
          )
        : SmartRefresher(
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: () {
              ref
                  .read(orderProvider.notifier)
                  .fetchHistoryOrdersPage(
                    context,
                    historyController,
                    isRefresh: true,
                  );
            },
            onLoading: () {
              ref
                  .read(orderProvider.notifier)
                  .fetchHistoryOrdersPage(context, historyController);
            },
            controller: historyController,
            child: ListView.builder(
              padding: EdgeInsets.only(
                top: 30.h,
                bottom: MediaQuery.paddingOf(context).bottom + 42.h,
              ),
              shrinkWrap: true,
              itemCount: state.historyOrders.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return OrdersItem(
                  isOrder: false,
                  order: state.historyOrders[index],
                );
              },
            ),
          );
    if (!widget.heading) {
      // The routed page: the app bar above owns the heading, and the
      // loading state sits under it exactly where it always did.
      return state.isHistoryLoading
          ? Align(alignment: Alignment.topCenter, child: list)
          : list;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
          child: const _OrderHistoryHeading(),
        ),
        Expanded(
          child: state.isHistoryLoading
              ? Align(alignment: Alignment.topCenter, child: list)
              : list,
        ),
      ],
    );
  }
}
