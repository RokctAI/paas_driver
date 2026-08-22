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
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:products_sdk/src/common/application/product/product_notifier.dart';
import 'package:products_sdk/src/common/application/product/product_state.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_notifier.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ProductMainButton extends StatelessWidget {
  final ShopOrderNotifier eventOrderShop;
  final ShopOrderState stateOrderShop;
  final ProductState state;
  final ProductNotifier event;
  final String? shopId;
  final String? cartId;
  final String? userUuid;

  const ProductMainButton({
    super.key,
    required this.state,
    required this.event,
    required this.stateOrderShop,
    required this.eventOrderShop,
    this.shopId,
    this.cartId,
    this.userUuid,
  });

  @override
  Widget build(BuildContext context) {
    num sumTotalPrice = 0;
    state.selectedStock?.addons?.forEach((element) {
      if (element.active ?? false) {
        sumTotalPrice += ((element.product?.stock?.totalPrice ?? 0) *
            (element.quantity ?? 1));
      }
    });
    sumTotalPrice =
        (sumTotalPrice + (state.selectedStock?.totalPrice ?? 0) * state.count);
    return Container(
      height: 130.h,
      color: AppStyle.cardDark,
      padding: EdgeInsets.only(right: 16.w, left: 16.w),
      child: Column(
        children: [
          16.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 50.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppStyle.textGrey),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        event.disCount(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 10.w,
                        ),
                        child: const Icon(Icons.remove),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text:
                            "${state.count * (state.productData?.interval ?? 1)}",
                        style: AppStyle.interSemi(
                          size: 14,
                          color: AppStyle.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text:
                                " ${state.productData?.unit?.translation?.title ?? ""}",
                            style: AppStyle.interSemi(
                              size: 14,
                              color: AppStyle.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        event.addCount(context);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.h,
                          horizontal: 10.w,
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 120.w,
                child: CustomButton(
                  isLoading: state.isAddLoading || state.isLoading,
                  title: AppHelpers.getTranslation(TrKeys.add),
                  onPressed: () {
                    if (LocalStorage.getToken().isNotEmpty) {
                      event.createCart(
                        context,
                        (state.productData!.shopId ?? ""),
                        () {
                          Navigator.pop(context);
                          eventOrderShop.getCart(
                            context,
                            () {},
                            shopId: shopId,
                            userUuid: userUuid,
                            cartId: cartId,
                          );
                        },
                        isGroupOrder: userUuid?.isNotEmpty ?? false,
                        cartId: cartId,
                        userUuid: userUuid,
                      );
                    } else {
                      AppRoutes.I.pushLoginRoute(context);
                    }
                  },
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.total),
                style: AppStyle.interNormal(size: 14, color: AppStyle.textPrimary),
              ),
              Text(
                AppHelpers.numberFormat(number: sumTotalPrice),
                style: AppStyle.interNoSemi(size: 20, color: AppStyle.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
