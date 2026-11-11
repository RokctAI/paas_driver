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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:delivery_sdk/src/driver/application/parcel/parcel_provider.dart';
import 'package:delivery_sdk/src/driver/presentation/home/driver_root_nav.dart';
import 'package:delivery_sdk/src/driver/presentation/widgets/driver_sheet_surface.dart';
import 'package:${package}/presentation/pages/parcel/parcel_item.dart';

import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/component/filter_screen.dart';
import 'package:${package}/presentation/routes/app_router.dart';
import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

@RoutePage()
class ParcelHistoryPage extends ConsumerStatefulWidget {
  const ParcelHistoryPage({super.key});

  @override
  ConsumerState<ParcelHistoryPage> createState() => _ParcelHistoryPageState();
}

class _ParcelHistoryPageState extends ConsumerState<ParcelHistoryPage> {
  late RefreshController historyController;

  @override
  void initState() {
    historyController = RefreshController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parcelProvider.notifier).fetchHistoryOrders(context);
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
    final state = ref.watch(parcelProvider);
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
                ),
              ),
              state.isHistoryLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Loading(),
                    )
                  : Expanded(
                      child: SmartRefresher(
                        enablePullDown: true,
                        enablePullUp: true,
                        onRefresh: () {
                          ref
                              .read(parcelProvider.notifier)
                              .fetchHistoryOrdersPage(
                                context,
                                historyController,
                                isRefresh: true,
                              );
                        },
                        onLoading: () {
                          ref
                              .read(parcelProvider.notifier)
                              .fetchHistoryOrdersPage(context, historyController);
                        },
                        controller: historyController,
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                            left: 16.r,
                            right: 16.r,
                            top: 30.h,
                            bottom: MediaQuery.paddingOf(context).bottom + 42.h,
                          ),
                          shrinkWrap: true,
                          itemCount: state.historyOrders.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return ParcelItem(
                              isOrder: false,
                              parcel: state.historyOrders[index],
                              isSet: false,
                            );
                          },
                        ),
                      ),
                    ),
            ],
          ),
          // Driver root tab pill: this page sits under the Jobs tab, so the
          // lit tab is Jobs and a tap on it does nothing (see _openRootTab).
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
                DriverSheet.show(
                  context,
                  paddingTop: MediaQuery.paddingOf(context).top,
                  modal: const FilterScreen(parcel: true),
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
}
