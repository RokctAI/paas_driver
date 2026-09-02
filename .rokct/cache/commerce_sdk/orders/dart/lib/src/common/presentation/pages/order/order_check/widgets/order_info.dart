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
