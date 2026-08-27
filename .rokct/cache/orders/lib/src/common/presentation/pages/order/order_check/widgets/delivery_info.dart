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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class DeliveryInfo extends StatelessWidget {
  const DeliveryInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return ref.watch(orderProvider).orderData?.deliveryMan == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  16.verticalSpace,
                  Container(
                    decoration: BoxDecoration(
                      color: AppStyle.bgGrey,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: CustomNetworkImage(
                            profile: true,
                            url: ref
                                    .watch(orderProvider)
                                    .orderData
                                    ?.deliveryMan
                                    ?.img ??
                                "",
                            height: 48,
                            width: 48,
                            radius: 0,
                          ),
                        ),
                        12.horizontalSpace,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${ref.watch(orderProvider).orderData?.deliveryMan?.firstname ?? ""} ${ref.watch(orderProvider).orderData?.deliveryMan?.lastname ?? ""}",
                              style: AppStyle.interSemi(
                                size: 16,
                                color: AppStyle.black,
                              ),
                            ),
                            Text(
                              AppHelpers.getTranslation(TrKeys.driver),
                              style: AppStyle.interRegular(
                                size: 12.sp,
                                color: AppStyle.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
      },
    );
  }
}
