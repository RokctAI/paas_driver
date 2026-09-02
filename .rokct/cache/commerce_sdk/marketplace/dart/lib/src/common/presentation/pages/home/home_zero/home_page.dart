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

import 'package:base_sdk/src/presentation/components/glance_card.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/application/currency/currency_provider.dart';
import 'package:base_sdk/src/application/home/home_notifier.dart';
import 'package:base_sdk/src/application/home/home_provider.dart';
import 'package:base_sdk/src/application/home/home_state.dart';
import 'package:base_sdk/src/application/main/main_provider.dart';
import 'package:base_sdk/src/application/map/view_map_provider.dart';
import 'package:base_sdk/src/application/profile/profile_provider.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/market_item.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/home/home_zero/widgets/door_to_door.dart';

import 'widgets/app_bar_home.dart';
import 'widgets/category_screen.dart';
import 'widgets/filter_category_shop.dart';
import 'shimmer/all_shop_shimmer.dart';
import 'shimmer/banner_shimmer.dart';
import 'shimmer/news_shop_shimmer.dart';
import 'shimmer/recommend_shop_shimmer.dart';
import 'shimmer/shop_shimmer.dart';
import 'widgets/banner_item.dart';
import 'widgets/recommended_item.dart';
import 'widgets/shop_bar_item.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late HomeNotifier event;
  final RefreshController _bannerController = RefreshController();
  final RefreshController _shopController = RefreshController();
  final RefreshController _categoryController = RefreshController();
  final RefreshController _storyController = RefreshController();
  late ScrollController _controller;

  @override
  void initState() {
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier)
        ..setAddress()
        ..fetchBanner(context)
        ..fetchShopRecommend(context)
        ..fetchShop(context)
        ..fetchStories(context)
        ..fetchAllShops(context)
        ..fetchNewShops(context)
        ..fetchAds(context)
        ..fetchCategories(context);
      ref
          .read(viewMapProvider.notifier)
          .checkAddress(context);
      ref.read(currencyProvider.notifier).fetchCurrency(context);
      if (LocalStorage.getToken().isNotEmpty) {
        ref.read(shopOrderProvider.notifier).getCart(context, () {});
        ref.read(profileProvider.notifier).fetchUser(context);
      }
    });
    _controller.addListener(listen);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    event = ref.read(homeProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _categoryController.dispose();
    _shopController.dispose();
    _storyController.dispose();
    _controller.removeListener(listen);
    super.dispose();
  }

  void listen() {
    final direction = _controller.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      ref.read(mainProvider.notifier).changeScrolling(true);
    } else if (direction == ScrollDirection.forward) {
      ref.read(mainProvider.notifier).changeScrolling(false);
    }
  }

  void _onLoading() {
    if (ref.watch(homeProvider).selectIndexCategory == -1) {
      event.fetchAllShopsPage(context, _shopController);
    } else {
      event.fetchFilterShops(context, controller: _shopController);
    }
  }

  void _onRefresh() {
    ref.watch(homeProvider).selectIndexCategory == -1
        ? (event
            ..fetchBannerPage(context, _shopController, isRefresh: true)
            ..fetchAllShopsPage(context, _shopController, isRefresh: true)
            ..fetchCategoriesPage(context, _shopController, isRefresh: true)
            ..fetchStoriesPage(context, _shopController, isRefresh: true)
            ..fetchShopPage(context, _shopController, isRefresh: true)
            ..fetchAds(context)
            ..fetchNewShopsPage(context, _shopController, isRefresh: true)
            ..fetchShopPageRecommend(context, _shopController, isRefresh: true))
        : event.fetchFilterShops(
            context,
            controller: _shopController,
            isRefresh: true,
          );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final bool isDarkMode = LocalStorage.getAppThemeMode();
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppStyle.mainBackDark : AppStyle.bgGrey,
        body: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          physics: const BouncingScrollPhysics(),
          controller: _shopController,
          scrollController: _controller,
          header: WaterDropMaterialHeader(
            distance: 160.h,
            backgroundColor: AppStyle.white,
            color: AppStyle.textGrey,
          ),
          onLoading: () => _onLoading(),
          onRefresh: () => _onRefresh(),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: 56.h),
              child: Column(
                children: [
                  AppBarHome(state: state, event: event),
                  const ActiveOrderGlanceCard(),
                  24.verticalSpace,
                  CategoryScreen(
                    state: state,
                    event: event,
                    categoryController: _categoryController,
                    shopController: _shopController,
                  ),
                  state.selectIndexCategory == -1
                      ? _body(state, context)
                      : FilterCategoryShop(
                          state: state,
                          event: event,
                          shopController: _shopController,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(HomeState state, BuildContext context) {
    return Column(
      children: [
        state.story?.isNotEmpty ?? false
            ? SizedBox(
                height: 200.r,
                child: SmartRefresher(
                  controller: _storyController,
                  scrollDirection: Axis.horizontal,
                  enablePullDown: false,
                  enablePullUp: true,
                  onLoading: () async {
                    await event.fetchStoriesPage(context, _storyController);
                  },
                  child: AnimationLimiter(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: state.story?.length ?? 0,
                      padding: EdgeInsets.only(left: 16.w),
                      itemBuilder: (context, index) =>
                          AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: ShopBarItem(
                                  index: index,
                                  controller: _storyController,
                                  story: state.story?[index]?.first,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
        16.verticalSpace,
        state.isBannerLoading
            ? const BannerShimmer()
            : Container(
                height: state.banners.isNotEmpty ? 200.h : 0,
                margin: EdgeInsets.only(
                  bottom: state.banners.isNotEmpty ? 30.h : 0,
                ),
                child: SmartRefresher(
                  scrollDirection: Axis.horizontal,
                  enablePullDown: false,
                  enablePullUp: true,
                  controller: _bannerController,
                  onLoading: () async {
                    await event.fetchBannerPage(context, _bannerController);
                  },
                  child: AnimationLimiter(
                    child: ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: state.banners.length,
                      padding: EdgeInsets.only(left: 16.w),
                      itemBuilder: (context, index) =>
                          AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: BannerItem(banner: state.banners[index]),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
        24.verticalSpace,
        state.isShopLoading
            ? ShopShimmer(title: AppHelpers.getTranslation(TrKeys.shops))
            : state.shops.isNotEmpty
            ? Column(
                children: [
                  TitleAndIcon(
                    rightTitle: AppHelpers.getTranslation(TrKeys.seeAll),
                    isIcon: true,
                    title: AppHelpers.getTranslation(TrKeys.favouriteBrand),
                    onRightTap: () {
                      AppRoutes.I.pushRecommendedRoute(context, isShop: true);
                    },
                  ),
                  12.verticalSpace,
                  AnimationLimiter(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: 1,
                            crossAxisCount: 2,
                          ),
                      padding: EdgeInsets.symmetric(horizontal: 16.r),
                      itemCount: state.shops.length,
                      itemBuilder: (context, index) =>
                          AnimationConfiguration.staggeredGrid(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            columnCount: state.shops.length,
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: MarketItem(
                                  isShop: true,
                                  shop: state.shops[index],
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  30.verticalSpace,
                ],
              )
            : const SizedBox.shrink(),
        if (AppHelpers.getParcel()) const DoorToDoor(),
        if (state.ads.isNotEmpty)
          Column(
            children: [
              TitleAndIcon(title: AppHelpers.getTranslation(TrKeys.newItem)),
              12.verticalSpace,
              Container(
                height: state.ads.isNotEmpty ? 200.h : 0,
                margin: EdgeInsets.only(
                  bottom: state.ads.isNotEmpty ? 30.h : 0,
                ),
                child: AnimationLimiter(
                  child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: state.ads.length,
                    padding: EdgeInsets.only(left: 16.w),
                    itemBuilder: (context, index) =>
                        AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: BannerItem(
                                isAds: true,
                                banner: state.ads[index],
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        24.verticalSpace,
        state.isShopRecommendLoading
            ? const RecommendShopShimmer()
            : state.shopsRecommend.isNotEmpty
            ? Column(
                children: [
                  TitleAndIcon(
                    rightTitle: AppHelpers.getTranslation(TrKeys.seeAll),
                    isIcon: true,
                    title: AppHelpers.getTranslation(TrKeys.recommended),
                    onRightTap: () {
                      context.router.pushNamed('/recommended');
                    },
                  ),
                  12.verticalSpace,
                  SizedBox(
                    height: 170.h,
                    child: AnimationLimiter(
                      child: ListView.builder(
                        shrinkWrap: false,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: state.shopsRecommend.length,
                        itemBuilder: (context, index) =>
                            AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: RecommendedItem(
                                    shop: state.shopsRecommend[index],
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  30.verticalSpace,
                ],
              )
            : const SizedBox.shrink(),
        state.isNewShopsLoading
            ? NewsShopShimmer(
                title: AppHelpers.getTranslation(TrKeys.newsOfWeek),
              )
            : state.newShops.isNotEmpty
            ? Column(
                children: [
                  TitleAndIcon(
                    rightTitle: AppHelpers.getTranslation(TrKeys.seeAll),
                    isIcon: true,
                    title: AppHelpers.getTranslation(TrKeys.newsOfWeek),
                    onRightTap: () {
                      AppRoutes.I.pushRecommendedRoute(context, isNewsOfPage: true);
                    },
                  ),
                  12.verticalSpace,
                  SizedBox(
                    height: 250.h,
                    child: AnimationLimiter(
                      child: ListView.builder(
                        padding: EdgeInsets.only(left: 16.r),
                        scrollDirection: Axis.horizontal,
                        itemCount: state.newShops.length,
                        itemBuilder: (context, index) =>
                            AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: MarketItem(
                                    shop: state.newShops[index],
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
        30.verticalSpace,
        state.isAllShopsLoading
            ? const AllShopShimmer()
            : Column(
                children: [
                  TitleAndIcon(
                    title: AppHelpers.getTranslation(TrKeys.allRestaurants),
                  ),
                  state.allShops.isNotEmpty
                      ? AnimationLimiter(
                          child: ListView.builder(
                            padding: EdgeInsets.only(top: 6.h),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            itemCount: state.allShops.length,
                            itemBuilder: (context, index) =>
                                AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: MarketItem(
                                        shop: state.allShops[index],
                                        isSimpleShop: true,
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        )
                      : SvgPicture.asset(
                          "assets/svgs/empty.svg",
                          height: 100.h,
                        ),
                ],
              ),
      ],
    );
  }
}
