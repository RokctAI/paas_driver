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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/application/home/home_notifier.dart';
import 'package:base_sdk/src/application/home/home_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/market_item.dart';
import 'recommended_item.dart';

// // // @RoutePage()
class RecommendedPage extends ConsumerStatefulWidget {
  final bool isNewsOfPage;
  final bool isShop;

  const RecommendedPage({
    super.key,
    this.isNewsOfPage = false,
    this.isShop = false,
  });

  @override
  ConsumerState<RecommendedPage> createState() => _RecommendedPageState();
}

class _RecommendedPageState extends ConsumerState<RecommendedPage> {
  late HomeNotifier event;
  final RefreshController _recommendedController = RefreshController();

  @override
  void didChangeDependencies() {
    event = ref.read(homeProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    return Scaffold(
      body: Column(
        children: [
          CommonAppBar(
            child: Text(
              AppHelpers.getTranslation(
                widget.isShop
                    ? TrKeys.shops
                    : widget.isNewsOfPage
                    ? TrKeys.newsOfWeek
                    : TrKeys.recommended,
              ),
              style: AppStyle.interNoSemi(size: 18.sp),
            ),
          ),
          widget.isShop
              ? Expanded(
                  child: state.shops.isNotEmpty
                      ? SmartRefresher(
                          controller: _recommendedController,
                          enablePullDown: true,
                          enablePullUp: true,
                          onLoading: () async {
                            await event.fetchShopPage(
                              context,
                              _recommendedController,
                            );
                          },
                          onRefresh: () async {
                            await event.fetchShopPage(
                              context,
                              _recommendedController,
                              isRefresh: true,
                            );
                          },
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: state.shops.length,
                            padding: EdgeInsets.symmetric(vertical: 24.h),
                            itemBuilder: (context, index) => MarketItem(
                              isSimpleShop: true,
                              shop: state.shops[index],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height / 2,
                              child: SvgPicture.asset("assets/svgs/empty.svg"),
                            ),
                            16.verticalSpace,
                            Text(
                              AppHelpers.getTranslation(TrKeys.noRestaurant),
                            ),
                          ],
                        ),
                )
              : widget.isNewsOfPage
              ? Expanded(
                  child: state.allShops.isNotEmpty
                      ? SmartRefresher(
                          controller: _recommendedController,
                          enablePullDown: true,
                          enablePullUp: true,
                          onLoading: () async {
                            await event.fetchAllShopsPage(
                              context,
                              _recommendedController,
                            );
                          },
                          onRefresh: () async {
                            await event.fetchAllShopsPage(
                              context,
                              _recommendedController,
                              isRefresh: true,
                            );
                          },
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: state.allShops.length,
                            padding: EdgeInsets.symmetric(vertical: 24.h),
                            itemBuilder: (context, index) => MarketItem(
                              shop: state.allShops[index],
                              isSimpleShop: true,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height / 2,
                              child: SvgPicture.asset("assets/svgs/empty.svg"),
                            ),
                            16.verticalSpace,
                            Text(
                              AppHelpers.getTranslation(TrKeys.noRestaurant),
                            ),
                          ],
                        ),
                )
              : Expanded(
                  child: state.shopsRecommend.isNotEmpty
                      ? SmartRefresher(
                          controller: _recommendedController,
                          enablePullDown: true,
                          enablePullUp: false,
                          onLoading: () async {
                            // await event.fetchShopPageRecommend(
                            //     context, _recommendedController);
                          },
                          onRefresh: () async {
                            await event.fetchShopPageRecommend(
                              context,
                              _recommendedController,
                              isRefresh: true,
                            );
                          },
                          child: GridView.builder(
                            shrinkWrap: true,
                            itemCount: state.shopsRecommend.length,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 24.h,
                            ),
                            itemBuilder: (context, index) => RecommendedItem(
                              shop: state.shopsRecommend[index],
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  childAspectRatio: 0.66.r,
                                  crossAxisCount: 2,
                                  mainAxisExtent: 190.h,
                                  mainAxisSpacing: 10.h,
                                ),
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height / 2,
                              child: SvgPicture.asset("assets/svgs/empty.svg"),
                            ),
                            16.verticalSpace,
                            Text(
                              AppHelpers.getTranslation(TrKeys.noRestaurant),
                            ),
                          ],
                        ),
                ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: const PopButton(),
      ),
    );
  }
}
