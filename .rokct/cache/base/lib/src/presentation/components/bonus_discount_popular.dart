// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/models/data/bonus_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class BonusDiscountPopular extends StatelessWidget {
  final bool isPopular;
  final BonusModel? bonus;
  final bool isDiscount;
  final bool isSingleShop;

  const BonusDiscountPopular({
    super.key,
    required this.isPopular,
    required this.bonus,
    required this.isDiscount,
    this.isSingleShop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        isDiscount && bonus != null && !isPopular
            ? Row(
                children: [
                  Container(
                    width: 22.w,
                    height: 22.h,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyle.red,
                    ),
                    child: Icon(
                      Remix.percent_fill,
                      size: 16.r,
                      color: AppStyle.white,
                    ),
                  ),
                  8.horizontalSpace,
                  Container(
                    width: 22.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyle.primary,
                    ),
                    child: Icon(
                      Remix.gift_2_fill,
                      size: 16.r,
                      color: AppStyle.black,
                    ),
                  ),
                ],
              )
            : isDiscount && isPopular && bonus == null
                ? Row(
                    children: [
                      Container(
                        width: 22.w,
                        height: 22.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppStyle.red,
                        ),
                        child: Icon(
                          Remix.percent_fill,
                          size: 16.r,
                          color: AppStyle.white,
                        ),
                      ),
                      8.horizontalSpace,
                      Container(
                        width: 22.w,
                        height: 22.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppStyle.blueBonus,
                        ),
                        child: Icon(
                          Remix.flashlight_fill,
                          size: 16.r,
                          color: AppStyle.white,
                        ),
                      ),
                    ],
                  )
                : isDiscount && isPopular && bonus != null
                    ? Row(
                        children: [
                          Container(
                            width: 22.w,
                            height: 22.h,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppStyle.red,
                            ),
                            child: Icon(
                              Remix.percent_fill,
                              size: 16.r,
                              color: AppStyle.white,
                            ),
                          ),
                          8.horizontalSpace,
                          Container(
                            width: 22.w,
                            height: 22.h,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppStyle.blueBonus,
                            ),
                            child: Icon(
                              Remix.flashlight_fill,
                              size: 16.r,
                              color: AppStyle.white,
                            ),
                          ),
                          8.horizontalSpace,
                          Container(
                            width: 22.w,
                            height: 22.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppStyle.primary,
                            ),
                            child: Icon(
                              Remix.gift_2_fill,
                              size: 16.r,
                              color: AppStyle.black,
                            ),
                          ),
                        ],
                      )
                    : isPopular && bonus != null && !isDiscount
                        ? Row(
                            children: [
                              Container(
                                width: 22.w,
                                height: 22.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppStyle.primary,
                                ),
                                child: Icon(
                                  Remix.gift_2_fill,
                                  size: 16.r,
                                  color: AppStyle.black,
                                ),
                              ),
                              8.horizontalSpace,
                              Container(
                                width: 22.w,
                                height: 22.h,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppStyle.blueBonus,
                                ),
                                child: Icon(
                                  Remix.flashlight_fill,
                                  size: 16.r,
                                  color: AppStyle.white,
                                ),
                              ),
                            ],
                          )
                        : isSingleShop
                            ? singleShop()
                            : Row(
                                children: [
                                  isDiscount
                                      ? Container(
                                          decoration: BoxDecoration(
                                            color: AppStyle.red,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(100.r),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 6.h,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Remix.percent_fill,
                                                  size: 14.r,
                                                  color: AppStyle.white,
                                                ),
                                                4.horizontalSpace,
                                                Text(
                                                  AppHelpers.getTranslation(
                                                    TrKeys.discount,
                                                  ).toUpperCase(),
                                                  style: AppStyle.interNoSemi(
                                                    size: 10.sp,
                                                    color: AppStyle.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : bonus != null
                                          ? Container(
                                              decoration: BoxDecoration(
                                                color: AppStyle.primary,
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(100.r),
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 6.h,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Remix.gift_2_fill,
                                                      size: 14.r,
                                                      color: AppStyle.black,
                                                    ),
                                                    4.horizontalSpace,
                                                    Text(
                                                      AppHelpers.getTranslation(
                                                        TrKeys.bonus,
                                                      ).toUpperCase(),
                                                      style:
                                                          AppStyle.interNoSemi(
                                                        size: 10.sp,
                                                        color: AppStyle.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : isPopular
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                    color: AppStyle.blueBonus,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(100.r),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 12.w,
                                                      vertical: 6.h,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Remix.flashlight_fill,
                                                          size: 14.r,
                                                          color: AppStyle.white,
                                                        ),
                                                        4.horizontalSpace,
                                                        Text(
                                                          AppHelpers
                                                              .getTranslation(
                                                            TrKeys.popular,
                                                          ).toUpperCase(),
                                                          style: AppStyle
                                                              .interNoSemi(
                                                            size: 10,
                                                            color:
                                                                AppStyle.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                ],
                              ),
      ],
    );
  }

  Widget singleShop() {
    return Row(
      children: [
        isDiscount
            ? Container(
                width: 22.w,
                height: 22.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppStyle.red,
                ),
                child: Icon(
                  Remix.percent_fill,
                  size: 16.r,
                  color: AppStyle.white,
                ),
              )
            : bonus != null
                ? Container(
                    width: 22.w,
                    height: 22.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyle.primary,
                    ),
                    child: Icon(
                      Remix.gift_2_fill,
                      size: 16.r,
                      color: AppStyle.black,
                    ),
                  )
                : isPopular
                    ? Container(
                        width: 22.w,
                        height: 22.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppStyle.blueBonus,
                        ),
                        child: Icon(
                          Remix.flashlight_fill,
                          size: 16.r,
                          color: AppStyle.white,
                        ),
                      )
                    : isDiscount && isPopular && bonus != null
                        ? Row(
                            children: [
                              Container(
                                width: 22.w,
                                height: 22.h,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppStyle.red,
                                ),
                                child: Icon(
                                  Remix.percent_fill,
                                  size: 16.r,
                                  color: AppStyle.white,
                                ),
                              ),
                              8.horizontalSpace,
                              Container(
                                width: 22.w,
                                height: 22.h,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppStyle.blueBonus,
                                ),
                                child: Icon(
                                  Remix.flashlight_fill,
                                  size: 16.r,
                                  color: AppStyle.white,
                                ),
                              ),
                              8.horizontalSpace,
                              Container(
                                width: 22.w,
                                height: 22.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppStyle.primary,
                                ),
                                child: Icon(
                                  Remix.gift_2_fill,
                                  size: 16.r,
                                  color: AppStyle.black,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
      ],
    );
  }
}
