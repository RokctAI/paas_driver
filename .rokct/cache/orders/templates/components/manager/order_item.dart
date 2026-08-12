import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/helper/common_image.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

class OrderItem extends StatelessWidget {
  final OrderData order;
  final bool isHistoryOrder;
  final VoidCallback onTap;

  const OrderItem({
    super.key,
    required this.order,
    required this.onTap,
    this.isHistoryOrder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 134.h,
          width: double.infinity,
          margin: REdgeInsets.only(bottom: 10),
          padding: REdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CommonImage(
                          url: order.user?.img,
                          radius: 25,
                          width: 50,
                          height: 50,
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.user == null
                                    ? AppHelpers.getTranslation(
                                        TrKeys.deletedUser)
                                    : '${order.user?.firstname ?? AppHelpers.getTranslation(TrKeys.noName)} ${order.user?.lastname ?? ''}',
                                style: AppStyle.interRegular(
                                  size: 14.sp,
                                  color: AppStyle.blackColor,
                                ),
                              ),
                              4.verticalSpace,
                              Text(
                                AppHelpers.getTranslation(
                                    order.deliveryType ?? ""),
                                style: AppStyle.interNormal(
                                  size: 12.sp,
                                  color: AppStyle.blackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (AppHelpers.getOrderStatus(order.status) ==
                      OrderStatus.open)
                    Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppStyle.red,
                      ),
                    ),
                  if (isHistoryOrder)
                    Text(AppHelpers.getTranslation(
                        order.transaction?.paymentSystem?.tag ?? ''))
                ],
              ),
              14.verticalSpace,
              Divider(color: AppStyle.bgGrey, thickness: 1.r, height: 1.r),
              14.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '№ ${order.id}',
                      style: AppStyle.interNormal(
                        color: AppStyle.blackColor,
                        size: 14.sp,
                        letterSpacing: -0.3,
                      ),
                      children: [
                        TextSpan(
                          text: ' | ',
                          style: AppStyle.interNormal(
                            color: AppStyle.borderColor,
                            size: 14.sp,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: '${order.deliveryDate ?? ''} ${order.deliveryTime ?? ''}',
                          style: AppStyle.interNormal(
                            color: AppStyle.blackColor,
                            size: 14.sp,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppHelpers.numberFormat(number: order.totalPrice?.isNegative ?? true
                            ? 0
                            : order.totalPrice ?? 0,
                        symbol: order.currency?.symbol),
                    style:
                        AppStyle.interNormal(size: 14.sp, color: AppStyle.blackColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
