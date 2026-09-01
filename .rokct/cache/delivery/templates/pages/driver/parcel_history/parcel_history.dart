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
import 'package:delivery_sdk/src/driver/application/parcel/parcel_provider.dart';
import 'package:${package}/presentation/pages/parcel/parcel_item.dart';

import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/component/filter_screen.dart';
import 'package:base_sdk/src/presentation/components/app_bars/custom_app_bar.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
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
      backgroundColor: AppStyle.bgGrey,
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
                  modal: const FilterScreen(parcel: true),
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
