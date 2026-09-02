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
