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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:products_sdk/src/common/application/product/product_notifier.dart';
import 'package:products_sdk/src/common/application/product/product_provider.dart';
import 'package:products_sdk/src/common/application/product/product_state.dart';
import 'package:base_sdk/src/application/shop/shop_provider.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_notifier.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_provider.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:base_sdk/src/models/data/review_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:products_sdk/src/common/presentation/pages/product/widgets/w_ingredient.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/application/shop/shop_state.dart';
// [refork] embed via EmbeddedWidgets
import 'package:products_sdk/src/common/presentation/pages/product/widgets/images_list_one.dart';
import 'package:products_sdk/src/common/presentation/pages/product/widgets/p_main_button.dart';
import 'package:products_sdk/src/common/presentation/pages/product/widgets/w_product_extras.dart';
import 'package:base_sdk/src/presentation/components/loading.dart';

class ProductScreen extends ConsumerStatefulWidget {
  final ProductData? data;
  final String? productId;
  final String? cartId;
  final ScrollController controller;

  const ProductScreen({
    this.productId,
    this.data,
    this.cartId,
    required this.controller,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  late bool isLtr;
  late ProductNotifier event;
  late ShopOrderNotifier eventOrderShop;
  late PageController controller;

  @override
  void initState() {
    controller = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productId != null) {
        ref.read(productProvider.notifier).getProductDetailsById(
              context,
              widget.productId ?? "",
              ref.watch(shopProvider).shopData?.type,
              ref.watch(shopProvider).shopData?.id,
              isLoading: true,
            );
      } else {
        ref.read(productProvider.notifier).getProductDetails(
              context,
              widget.data!,
              ref.watch(shopProvider).shopData?.type,
              ref.watch(shopProvider).shopData?.id,
            );
      }
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    isLtr = LocalStorage.getLangLtr();
    event = ref.read(productProvider.notifier);
    eventOrderShop = ref.read(shopOrderProvider.notifier);
    super.didChangeDependencies();
  }

  @override
  void deactivate() {
    controller.dispose();
    super.deactivate();
  }

  void checkShopOrder({
    required ProductNotifier event,
    required ProductState state,
    required ShopOrderNotifier eventOrderShop,
    required ShopState shopState,
  }) {
    AppHelpers.showAlertDialog(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.allPreviouslyAdded),
            style: AppStyle.interNormal(),
            textAlign: TextAlign.center,
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.cancel),
                  background: AppStyle.transparent,
                  borderColor: AppStyle.borderColor,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: Consumer(
                  builder: (contextTwo, ref, child) {
                    return CustomButton(
                      isLoading: ref.watch(shopOrderProvider).isDeleteLoading,
                      title: AppHelpers.getTranslation(TrKeys.continueText),
                      onPressed: () {
                        eventOrderShop.deleteCart(context).then((value) async {
                          event.createCart(
                            // ignore: use_build_context_synchronously
                            context,
                            ref.watch(shopOrderProvider).cart?.shopId ??
                                (state.productData!.shopId ?? ""),
                            () {
                              eventOrderShop.getCart(
                                context,
                                () {},
                                cartId: widget.cartId,
                                shopId: shopState.shopData?.id.toString(),
                                userUuid: shopState.userUuid,
                              );
                              Navigator.pop(context);
                            },
                            isGroupOrder: shopState.userUuid.isNotEmpty,
                            cartId: ref
                                .watch(shopOrderProvider)
                                .cart
                                ?.id
                                .toString(),
                            userUuid: shopState.userUuid,
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final stateOrderShop = ref.watch(shopOrderProvider);
    final stateShop = ref.watch(shopProvider);
    ref.listen(productProvider, (previous, next) {
      if (next.isCheckShopOrder &&
          (next.isCheckShopOrder != (previous?.isCheckShopOrder ?? false))) {
        checkShopOrder(
          event: event,
          state: state,
          eventOrderShop: eventOrderShop,
          shopState: stateShop,
        );
      }
    });
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyle.bgGrey.withOpacity(0.96),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        width: double.infinity,
        child: state.isLoading
            ? const Loading()
            : SingleChildScrollView(
                controller: widget.controller,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          8.verticalSpace,
                          Center(
                            child: Container(
                              height: 4.h,
                              width: 48.w,
                              decoration: BoxDecoration(
                                color: AppStyle.dragElement,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(40.r),
                                ),
                              ),
                            ),
                          ),
                          14.verticalSpace,
                          Row(
                            children: [
                              Expanded(
                                child: TitleAndIcon(
                                  title:
                                      state.productData?.translation?.title ??
                                          "",
                                  paddingHorizontalSize: 0,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => event.shareProduct(),
                                child: Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    color: AppStyle.transparent,
                                    border: Border.all(color: AppStyle.black),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: const Center(
                                    child: Icon(Remix.share_line),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          20.verticalSpace,
                          Stack(
                            children: [
                              SizedBox(
                                height: 200.r,
                                child: PageView.builder(
                                  itemCount:
                                      state.productData?.galleries?.length ?? 0,
                                  controller: controller,
                                  onPageChanged: (index) {
                                    event.changeImage(
                                      state.productData?.galleries?[index] ??
                                          Galleries(),
                                    );
                                  },
                                  itemBuilder: (context, index) {
                                    return CustomNetworkImage(
                                      url: state.selectImage?.path ??
                                          state.activeImageUrl,
                                      height: 200,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      radius: 10,
                                    );
                                  },
                                ),
                              ),
                              if ((state.productData?.galleries?.length ?? 0) >
                                  1)
                                Positioned(
                                  bottom: 8.r,
                                  child: ImagesOneList(
                                    list: state.productData?.galleries,
                                    selectImageId: state.selectImage?.id,
                                  ),
                                ),
                              // 18+ (adults only) badge — mirrors the
                              // base_sdk ProductCard badge, driven by the
                              // backend `is_adult` flag.
                              if (state.productData?.isAdult == true)
                                Positioned(
                                  top: 8.r,
                                  right: 8.r,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppStyle.red,
                                      borderRadius:
                                          BorderRadius.circular(100.r),
                                    ),
                                    child: Text(
                                      "18+",
                                      style: AppStyle.interNoSemi(
                                        size: 10,
                                        color: AppStyle.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          state.selectedStock?.bonus != null
                              ? Padding(
                                  padding: EdgeInsets.only(top: 12.h),
                                  child: Row(
                                    children: [
                                      AnimationButtonEffect(
                                        child: InkWell(
                                          onTap: () {
                                            AppHelpers
                                                .showCustomModalBottomSheet(
                                              context: context,
                                              modal: EmbeddedWidgets.I.bonusScreen(
                                                bonus:
                                                    state.selectedStock?.bonus,
                                              ),
                                              isDarkMode: false,
                                              isDrag: true,
                                              radius: 12,
                                            );
                                          },
                                          child: Container(
                                            width: 22.w,
                                            height: 22.h,
                                            margin: EdgeInsets.all(8.r),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppStyle.blueBonus,
                                            ),
                                            child: Icon(
                                              Remix.gift_2_fill,
                                              size: 16.r,
                                              color: AppStyle.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      4.horizontalSpace,
                                      Text(
                                        ((state.selectedStock?.bonus?.type ??
                                                    "sum") ==
                                                "sum")
                                            ? "${AppHelpers.getTranslation(TrKeys.under)} ${AppHelpers.numberFormat(number: state.selectedStock?.bonus?.value ?? 0)} + ${state.selectedStock?.bonus?.bonusStock?.product?.translation?.title ?? ""}"
                                            : "${AppHelpers.getTranslation(TrKeys.under)} ${state.selectedStock?.bonus?.value ?? 0} + ${state.selectedStock?.bonus?.bonusStock?.product?.translation?.title ?? ""}",
                                        style: AppStyle.interRegular(
                                          size: 14,
                                          color: AppStyle.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                          15.verticalSpace,
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    state.productData?.translation
                                            ?.description ??
                                        "",
                                    style: AppStyle.interRegular(
                                      size: 14.sp,
                                      color: AppStyle.textGrey,
                                    ),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      AppHelpers.numberFormat(
                                        number:
                                            (state.selectedStock?.price ?? 0) +
                                                (state.selectedStock?.tax ?? 0),
                                      ),
                                      style: AppStyle.interRegular(
                                        size: 14.sp,
                                        color: AppStyle.black,
                                        textDecoration:
                                            state.selectedStock?.discount ==
                                                    null
                                                ? TextDecoration.none
                                                : TextDecoration.lineThrough,
                                      ),
                                    ),
                                    state.selectedStock?.discount == null
                                        ? const SizedBox.shrink()
                                        : Container(
                                            margin: EdgeInsets.only(top: 8.r),
                                            decoration: BoxDecoration(
                                              color: AppStyle.redBg,
                                              borderRadius:
                                                  BorderRadius.circular(30.r),
                                            ),
                                            padding: EdgeInsets.all(4.r),
                                            child: Row(
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/svgs/discount.svg",
                                                ),
                                                8.horizontalSpace,
                                                Text(
                                                  AppHelpers.numberFormat(
                                                    number: state.selectedStock
                                                        ?.totalPrice,
                                                  ),
                                                  style: AppStyle.interNoSemi(
                                                    size: 12,
                                                    color: AppStyle.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          24.verticalSpace,
                          const WProductExtras(),
                          24.verticalSpace,
                          WIngredientScreen(
                            list: state.selectedStock?.addons ?? [],
                            onChange: (int value) {
                              event.updateIngredient(context, value);
                            },
                            add: (int value) {
                              event.addIngredient(context, value);
                            },
                            remove: (int value) {
                              event.removeIngredient(context, value);
                            },
                          ),
                        ],
                      ),
                    ),
                    20.verticalSpace,
                    ProductMainButton(
                      state: state,
                      event: event,
                      stateOrderShop: stateOrderShop,
                      eventOrderShop: eventOrderShop,
                      cartId: stateOrderShop.cart?.id.toString(),
                      shopId: ref.watch(shopProvider).shopData?.id,
                      userUuid: ref.watch(shopProvider).userUuid,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
