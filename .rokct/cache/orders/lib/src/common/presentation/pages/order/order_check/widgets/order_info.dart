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
import 'package:base_sdk/src/services/time_service.dart';
import 'package:base_sdk/src/application/order/order_provider.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class OrderInfo extends StatelessWidget {
  const OrderInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.order),
                style: AppStyle.interNoSemi(size: 16, color: AppStyle.black),
              ),
              8.verticalSpace,
              Row(
                children: [
                  Text(
                    "#${AppHelpers.getTranslation(TrKeys.id)}${ref.read(orderProvider).orderData?.id ?? ""}",
                    style: AppStyle.interNormal(
                      size: 14,
                      color: AppStyle.textGrey,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12.w),
                    width: 6.w,
                    height: 6.h,
                    decoration: const BoxDecoration(
                      color: AppStyle.textGrey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    TimeService.dateFormatMDHm(
                      ref.read(orderProvider).orderData?.createdAt ??
                          DateTime.now(),
                    ),
                    style: AppStyle.interNormal(
                      size: 14,
                      color: AppStyle.textGrey,
                    ),
                  ),
                ],
              ),
              if (ref.watch(orderProvider).orderData?.address?.address != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    16.verticalSpace,
                    const Divider(color: AppStyle.textGrey),
                    16.verticalSpace,
                    Text(
                      AppHelpers.getTranslation(TrKeys.deliveryAddress),
                      style: AppStyle.interRegular(
                        size: 14,
                        color: AppStyle.textGrey,
                      ),
                    ),
                    Text(
                      ref.watch(orderProvider).orderData?.address?.address ??
                          "",
                      style: AppStyle.interNoSemi(
                        size: 16,
                        color: AppStyle.black,
                      ),
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  16.verticalSpace,
                  const Divider(color: AppStyle.textGrey),
                  16.verticalSpace,
                  Text(
                    AppHelpers.getTranslation(TrKeys.tellThisCodeToDriver),
                    style: AppStyle.interRegular(
                      size: 14,
                      color: AppStyle.textGrey,
                    ),
                  ),
                  Text(
                    "${ref.watch(orderProvider).orderData?.otp}",
                    style: AppStyle.interNoSemi(
                      size: 16,
                      color: AppStyle.black,
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              const Divider(color: AppStyle.textGrey),
            ],
          ),
        );
      },
    );
  }
}
