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
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:marketplace_sdk/src/common/application/customer/filter/filter_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/home/home_zero/widgets/market_one_item.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/home/home_zero/widgets/market_three_item.dart';
import 'package:marketplace_sdk/src/common/application/customer/filter/filter_notifier.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/market_item.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/home/home_zero/widgets/market_two_item.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/home/home_zero/shimmer/all_shop_shimmer.dart';

// // // @RoutePage()
class ResultFilterPage extends ConsumerStatefulWidget {
  final String categoryId;

  const ResultFilterPage({super.key, required this.categoryId});

  @override
  ConsumerState<ResultFilterPage> createState() => _ResultFilterState();
}

class _ResultFilterState extends ConsumerState<ResultFilterPage> {
  late FilterNotifier event;
  final RefreshController _shopController = RefreshController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(filterProvider.notifier)
          .fetchAllShops(context, widget.categoryId);
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(filterProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _shopController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(filterProvider);
    return Scaffold(
      body: Column(
        children: [
          CommonAppBar(
            child: Text(
              AppHelpers.getTranslation(TrKeys.shops),
              style: AppStyle.interNoSemi(size: 18.sp),
            ),
          ),
          Expanded(
            child: SmartRefresher(
              controller: _shopController,
              enablePullUp: true,
              enablePullDown: true,
              onLoading: () {
                event.fetchAllShopsPage(
                  context,
                  _shopController,
                  widget.categoryId,
                );
              },
              onRefresh: () {
                event.fetchAllShopsPage(
                  context,
                  _shopController,
                  widget.categoryId,
                  isRefresh: true,
                );
              },
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    24.verticalSpace,
                    state.isAllShopsLoading
                        ? const AllShopShimmer()
                        : Column(
                            children: [
                              TitleAndIcon(
                                title: AppHelpers.getTranslation(
                                  TrKeys.allShops,
                                ),
                                rightTitle:
                                    "${AppHelpers.getTranslation(TrKeys.found)} ${state.allShops.length.toString()} ${AppHelpers.getTranslation(TrKeys.results)}",
                              ),
                              ListView.builder(
                                padding: EdgeInsets.only(top: 6.h),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                scrollDirection: Axis.vertical,
                                itemCount: state.allShops.length,
                                itemBuilder: (context, index) =>
                                    AppHelpers.getType() == 0
                                    ? MarketItem(
                                        shop: state.allShops[index],
                                        isSimpleShop: true,
                                      )
                                    : AppHelpers.getType() == 1
                                    ? MarketOneItem(
                                        shop: state.allShops[index],
                                        isSimpleShop: true,
                                      )
                                    : AppHelpers.getType() == 2
                                    ? MarketTwoItem(
                                        shop: state.allShops[index],
                                        isSimpleShop: true,
                                        isFilter: true,
                                      )
                                    : MarketThreeItem(
                                        shop: state.allShops[index],
                                        isSimpleShop: true,
                                      ),
                              ),
                            ],
                          ),
                  ],
                ),
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
    );
  }
}
