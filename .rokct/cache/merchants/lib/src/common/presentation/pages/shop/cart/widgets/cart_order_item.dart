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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/models/data/addons_data.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:merchants_sdk/src/common/presentation/pages/shop/cart/widgets/note_product.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';

class CartOrderItem extends StatelessWidget {
  final CartDetail? cart;
  final Detail? cartTwo;
  final String? symbol;
  final VoidCallback add;
  final VoidCallback remove;
  final bool isActive;
  final bool isOwn;
  final bool isAddComment;

  const CartOrderItem({
    super.key,
    required this.add,
    required this.remove,
    required this.cart,
    this.isActive = true,
    this.cartTwo,
    this.isOwn = true,
    this.symbol,
    this.isAddComment = false,
  });

  @override
  Widget build(BuildContext context) {
    num sumPrice = 0;
    num disSumPrice = 0;
    for (Addons e in (isActive ? cart?.addons ?? [] : cartTwo?.addons ?? [])) {
      sumPrice += (e.price ?? 0);
    }
    disSumPrice = (isActive
                ? (cart?.stock?.totalPrice ?? 0)
                : (cartTwo?.stock?.totalPrice ?? 0)) *
            (cart?.quantity ?? 1) +
        sumPrice +
        (isActive ? (cart?.discount ?? 0) : (cartTwo?.discount ?? 0));
    sumPrice += (isActive
            ? (cart?.stock?.totalPrice ?? 0)
            : (cartTwo?.stock?.totalPrice ?? 0)) *
        (isActive ? (cart?.quantity ?? 1) : (cartTwo?.quantity ?? 1));

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Container(
        padding: EdgeInsets.all(16.r),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.all(Radius.circular(10.r)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: (MediaQuery.sizeOf(context).width - 86.w) * 2 / 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  isActive
                      ? RichText(
                          text: TextSpan(
                            text:
                                cart?.stock?.product?.translation?.title ?? "",
                            style: AppStyle.interNormal(
                              size: 16,
                              color: AppStyle.textPrimary,
                            ),
                            children: [
                              if (cart?.stock?.extras?.isNotEmpty ?? false)
                                TextSpan(
                                  text:
                                      " (${cart?.stock?.extras?.first.value ?? ""})",
                                  style: AppStyle.interNormal(
                                    size: 14,
                                    color: AppStyle.textGrey,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                cartTwo?.stock?.product?.translation?.title ??
                                    "",
                                style: AppStyle.interNormal(
                                  size: 16,
                                  color: AppStyle.textPrimary,
                                ),
                              ),
                            ),
                            if (cartTwo?.stock?.extras?.isNotEmpty ?? false)
                              Text(
                                " (${cartTwo?.stock?.extras?.first.value ?? ""})",
                                style: AppStyle.interNormal(
                                  size: 14,
                                  color: AppStyle.textGrey,
                                ),
                              ),
                          ],
                        ),
                  8.verticalSpace,
                  isActive
                      ? Text(
                          (cart?.stock?.product?.translation?.description ??
                              ""),
                          style: AppStyle.interNormal(
                            size: 12,
                            color: AppStyle.textGrey,
                          ),
                          maxLines: 2,
                        )
                      : Text(
                          cartTwo?.stock?.product?.translation?.description ??
                              "",
                          style: AppStyle.interNormal(
                            size: 12.sp,
                            color: AppStyle.textGrey,
                          ),
                          maxLines: 2,
                        ),
                  8.verticalSpace,
                  for (Addons e in (isActive
                      ? cart?.addons ?? []
                      : cartTwo?.addons ?? []))
                    Text(
                      "${e.stocks?.product?.translation?.title ?? ""} ${AppHelpers.numberFormat(symbol: symbol, isOrder: symbol != null, number: (e.price ?? 0) / (e.quantity ?? 1))} x ${(e.quantity ?? 1)}",
                      style: AppStyle.interNormal(
                        size: 13.sp,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                  8.verticalSpace,
                  isActive
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: AppStyle.textGrey),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ((cart?.bonus ?? false) || !isOwn)
                                      ? const SizedBox.shrink()
                                      : GestureDetector(
                                          onTap: remove,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 6.h,
                                              horizontal: 10.w,
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              color: AppStyle.textPrimary,
                                            ),
                                          ),
                                        ),
                                  Padding(
                                    padding: !((cart?.bonus ?? false) || !isOwn)
                                        ? EdgeInsets.zero
                                        : EdgeInsets.symmetric(
                                            vertical: 6.h,
                                            horizontal: 16.w,
                                          ),
                                    child: RichText(
                                      text: TextSpan(
                                        text:
                                            "${(cart?.quantity ?? 1) * (cart?.stock?.product?.interval ?? 1)}",
                                        style: AppStyle.interSemi(
                                          size: 14,
                                          color: AppStyle.textPrimary,
                                        ),
                                        children: [
                                          TextSpan(
                                            text:
                                                " ${cart?.stock?.product?.unit?.translation?.title ?? ''}",
                                            style: AppStyle.interSemi(
                                              size: 14,
                                              color: AppStyle.textGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ((cart?.bonus ?? false) || !isOwn)
                                      ? const SizedBox.shrink()
                                      : GestureDetector(
                                          onTap: add,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 6.h,
                                              horizontal: 10.w,
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              color: AppStyle.textPrimary,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            16.verticalSpace,
                            !(cart?.bonus ?? false)
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppHelpers.numberFormat(
                                          isOrder: symbol != null,
                                          symbol: symbol,
                                          number: (cart?.discount ?? 0) != 0
                                              ? disSumPrice
                                              : sumPrice,
                                        ),
                                        style: AppStyle.interSemi(
                                          size: (cart?.discount ?? 0) != 0
                                              ? 12
                                              : 16,
                                          color: AppStyle.textPrimary,
                                          decoration: (cart?.discount ?? 0) != 0
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                      (cart?.discount ?? 0) != 0
                                          ? Container(
                                              margin: EdgeInsets.only(top: 8.r),
                                              decoration: BoxDecoration(
                                                color: AppStyle.redBg,
                                                borderRadius:
                                                    BorderRadius.circular(30.r),
                                              ),
                                              padding: EdgeInsets.all(4.r),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/svgs/discount.svg",
                                                  ),
                                                  4.horizontalSpace,
                                                  Text(
                                                    AppHelpers.numberFormat(
                                                      isOrder: symbol != null,
                                                      symbol: symbol,
                                                      number: sumPrice,
                                                    ),
                                                    style: AppStyle.interNoSemi(
                                                      size: 14,
                                                      color: AppStyle.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ],
                        )
                      : !(cartTwo?.bonus ?? false)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppHelpers.numberFormat(
                                        isOrder: symbol != null,
                                        symbol: symbol,
                                        number: cartTwo?.stock?.totalPrice,
                                      ),
                                      style: AppStyle.interSemi(
                                        size: 16,
                                        color: AppStyle.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      " X ${(cartTwo?.quantity ?? 1)}",
                                      style: AppStyle.interSemi(
                                        size: 16,
                                        color: AppStyle.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      " (${(cartTwo?.quantity ?? 1) * (cartTwo?.stock?.product?.interval ?? 1)} ${cartTwo?.stock?.product?.unit?.translation?.title})",
                                      style: AppStyle.interNormal(
                                        size: 12,
                                        color: AppStyle.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                8.verticalSpace,
                                Text(
                                  AppHelpers.numberFormat(
                                    isOrder: symbol != null,
                                    symbol: symbol,
                                    number: sumPrice,
                                  ),
                                  style: AppStyle.interSemi(
                                    size: 16,
                                    color: AppStyle.textPrimary,
                                  ),
                                ),
                                8.horizontalSpace,
                              ],
                            )
                          : Row(
                              children: [
                                Text(
                                  AppHelpers.getTranslation(
                                    (cartTwo?.bonusShop ?? false)
                                        ? TrKeys.shopBonus
                                        : TrKeys.bonus,
                                  ),
                                  style: AppStyle.interSemi(
                                    size: 16,
                                    color: AppStyle.textPrimary,
                                  ),
                                ),
                                Text(
                                  " (${(cartTwo?.quantity ?? 1) * (cartTwo?.stock?.product?.interval ?? 1)} ${cartTwo?.stock?.product?.unit?.translation?.title})",
                                  style: AppStyle.interNormal(
                                    size: 12,
                                    color: AppStyle.textGrey,
                                  ),
                                ),
                              ],
                            ),
                ],
              ),
            ),
            4.horizontalSpace,
            Expanded(
              child: Stack(
                children: [
                  CustomNetworkImage(
                    url: isActive
                        ? cart?.stock?.product?.img ?? ""
                        : cartTwo?.stock?.product?.img ?? "",
                    height: 120.h,
                    width: double.infinity,
                    radius: 10.r,
                  ),
                  (cart?.bonus ?? false) || (cartTwo?.bonus ?? false)
                      ? Positioned(
                          bottom: 4.r,
                          right: 4.r,
                          child: Container(
                            width: 22.w,
                            height: 22.h,
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
                        )
                      : const SizedBox.shrink(),
                  if (isAddComment)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Consumer(
                        builder: (context, provider, child) {
                          return IconButton(
                            onPressed: () {
                              AppHelpers.showAlertDialog(
                                context: context,
                                child: NoteProduct(
                                  isSave: cartTwo == null,
                                  comment: cartTwo?.note,
                                  onTap: (s) {
                                    provider
                                        .read(orderProvider.notifier)
                                        .setNotes(
                                          stockId: cart?.stock?.id ?? "",
                                          note: s,
                                        );
                                  },
                                ),
                              );
                            },
                            icon: Icon(
                              Remix.edit_box_line,
                              size: 24.r,
                              color: AppStyle.red,
                            ),
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
    );
  }
}
