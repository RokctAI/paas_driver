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

// ignore_for_file: unused_result

import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' as l;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/application/order/order_notifier.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/application/order/order_state.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_state.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';
import 'package:base_sdk/src/presentation/components/shop_avarat.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/application/payment_methods/payment_provider.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/order_check.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_type/widgets/order_map.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_type/order_type.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_check/widgets/rating_page.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_screen/widgets/order_carts.dart';
import 'package:orders_sdk/src/common/presentation/pages/order/order_screen/widgets/order_status.dart';

@RoutePage()
class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({super.key});

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage>
    with SingleTickerProviderStateMixin {
  late RefreshController refreshController;
  late TabController _tabController;
  late ConfettiController _controllerCenter;
  late double long;
  late double lat;
  int tabIndex = 0;
  int reviewOpen = 1;
  bool check = false;

  void getAddress() {
    long = LocalStorage.getAddressSelected()?.location?.longitude ??
        AppConstants.demoLongitude;
    lat = LocalStorage.getAddressSelected()?.location?.latitude ??
        AppConstants.demoLatitude;
  }

  checkCart(ShopOrderState stateShopOrder, OrderState state) {
    final cart = stateShopOrder.cart;
    check = !(!(cart == null ||
            (cart.userCarts?.isEmpty ?? true) ||
            ((cart.userCarts?.isEmpty ?? true)
                    ? true
                    : (cart.userCarts?.first.cartDetails?.isEmpty ?? true)) &&
                !(cart.group ?? false)) ||
        state.orderData != null);
  }

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _controllerCenter = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    refreshController = RefreshController();
    if (ref.read(shopOrderProvider).cart != null) {
      _tabController.addListener(() {
        ref.read(orderProvider.notifier).changeTabIndex(_tabController.index);
        if (_tabController.index == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(orderProvider.notifier).getCalculate(
                  isLoading: false,
                  context: context,
                  cartId: ref.read(shopOrderProvider).cart?.id ?? "",
                  long: long,
                  lat: lat,
                  type: DeliveryTypeEnum.pickup,
                );
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(orderProvider.notifier).getCalculate(
                  isLoading: false,
                  context: context,
                  cartId: ref.read(shopOrderProvider).cart?.id ?? "",
                  long: long,
                  lat: lat,
                  type: DeliveryTypeEnum.delivery,
                );
          });
        }
      });
      getAddress();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(shopOrderProvider.notifier).getCart(context, () {});
        ref.read(orderProvider.notifier)
          ..resetState()
          ..fetchShop(
            context,
            (ref.watch(shopOrderProvider).cart?.shopId ?? "").toString(),
          )
          ..fetchShopBranch(
            context,
            (ref.watch(shopOrderProvider).cart?.shopId ?? ""),
          )
          ..getCalculate(
            context: context,
            cartId: ref.watch(shopOrderProvider).cart?.id ?? "",
            long: long,
            lat: lat,
            type: DeliveryTypeEnum.delivery,
          );
        ref.refresh(paymentProvider);
        ref.read(paymentProvider.notifier).fetchPayments(context);
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = LocalStorage.getAppThemeMode();
    final isLtr = LocalStorage.getLangLtr();
    final state = ref.watch(orderProvider);
    final event = ref.read(orderProvider.notifier);
    checkCart(ref.watch(shopOrderProvider), state);
    ref.listen(orderProvider, (previous, next) {
      if (AppHelpers.getOrderStatus(next.orderData?.status ?? "") ==
              OrderStatus.delivered &&
          next.orderData?.review == null &&
          previous?.orderData?.status != next.orderData?.status) {
        AppHelpers.showCustomModalBottomSheet(
          context: context,
          modal: RatingPage(totalPrice: next.orderData?.totalPrice),
          isDarkMode: isDarkMode,
        );
      }
    });

    ref.listen(orderProvider, (previous, next) {
      if (next.shopData != null && (previous?.shopData != next.shopData)) {
        ref.read(paymentProvider.notifier).fetchPayments(
              context,
              shopEnableCod: next.shopData?.enableCod ?? true,
            );
      }
    });
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: KeyboardDismisser(
        child: ConfettiWidget(
          blastDirectionality: BlastDirectionality.explosive,
          confettiController: _controllerCenter,
          particleDrag: 0.02,
          emissionFrequency: 0.02,
          numberOfParticles: 45,
          gravity: 0.1,
          shouldLoop: false,
          displayTarget: true,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor:
                isDarkMode ? AppStyle.mainBackDark : AppStyle.bgGrey,
            body: check
                ? _resultEmpty()
                : state.isLoading
                    ? const Loading()
                    : _orderScreen(context, state, event),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: _bottom(state, context),
          ),
        ),
      ),
    );
  }

  Widget _bottom(OrderState state, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(children: [const PopButton(), 16.horizontalSpace]),
    );
  }

  Widget _orderScreen(
    BuildContext context,
    OrderState state,
    OrderNotifier event,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _appBar(context, state),
        Expanded(
          child: SmartRefresher(
            enablePullDown: state.orderData != null,
            enablePullUp: false,
            controller: state.orderData == null
                ? RefreshController()
                : refreshController,
            onRefresh: () {
              event.showOrder(context, state.orderData?.id ?? "", true);
              refreshController.refreshCompleted();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  16.verticalSpace,
                  state.orderData != null
                      ? OrderMap(
                          isLoading: state.isMapLoading,
                          polylineCoordinates: state.polylineCoordinates,
                          markers: Set<Marker>.of(state.markers.values),
                          latLng: LatLng(
                            state.orderData?.shop?.location?.latitude ?? 0,
                            state.orderData?.shop?.location?.longitude ?? 0,
                          ),
                        )
                      : OrderType(
                          sendUser: ref.watch(orderProvider).sendOtherUser,
                          shopId: state.shopData?.id ?? "",
                          tabController: _tabController,
                          onChange: (s) => event.changeActive(s),
                          getLocation: () {
                            getAddress();
                            event.getCalculate(
                              isLoading: false,
                              context: context,
                              cartId:
                                  ref.read(shopOrderProvider).cart?.id ?? "",
                              long: long,
                              lat: lat,
                              type: _tabController.index == 0
                                  ? DeliveryTypeEnum.delivery
                                  : DeliveryTypeEnum.pickup,
                            );
                          },
                        ),
                  Stack(
                    children: [
                      OrderCarts(
                        lat: lat,
                        long: long,
                        tabBarIndex: _tabController.index,
                      ),
                      if (ref.watch(shopOrderProvider).isAddAndRemoveLoading)
                        _customLoading(),
                    ],
                  ),
                  OrderCheck(
                    orderStatus: AppHelpers.getOrderStatus(
                      state.orderData?.status ?? "",
                    ),
                    isOrder: state.orderData != null,
                    isActive: state.isActive,
                    controllerCenter: _controllerCenter,
                  ),
                  64.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultEmpty() {
    return Column(
      children: [
        100.verticalSpace,
        l.Lottie.asset('assets/lottie/girl_empty.json'),
        24.verticalSpace,
        Text(
          AppHelpers.getTranslation(TrKeys.cartIsEmpty),
          style: AppStyle.interSemi(size: 18.sp),
        ),
      ],
    );
  }

  CommonAppBar _appBar(BuildContext context, OrderState state) {
    return CommonAppBar(
      height: state.orderData != null ? 170 : 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ShopAvatar(
                shopImage: state.orderData == null
                    ? (state.shopData?.logoImg ?? "")
                    : (state.orderData?.shop?.logoImg ?? ""),
                size: 40,
                padding: 4,
                radius: 8,
                bgColor: AppStyle.black.withOpacity(0.06),
              ),
              10.horizontalSpace,
              SizedBox(
                width: MediaQuery.sizeOf(context).width - 86.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      state.orderData == null
                          ? (state.shopData?.translation?.title ?? "")
                          : (state.orderData?.shop?.translation?.title ?? ""),
                      style: AppStyle.interSemi(
                        size: 16,
                        color: AppStyle.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      state.orderData == null
                          ? (state.shopData?.translation?.description ?? "")
                          : (state.orderData?.shop?.translation?.description ??
                              ""),
                      style: AppStyle.interNormal(
                        size: 12,
                        color: AppStyle.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          state.orderData != null
              ? OrderStatusScreen(
                  status: AppHelpers.getOrderStatus(
                    state.orderData?.status ?? "",
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

Widget _customLoading() {
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
    child: Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(color: AppStyle.white.withOpacity(0.5)),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: const Loading(),
      ),
    ),
  );
}
