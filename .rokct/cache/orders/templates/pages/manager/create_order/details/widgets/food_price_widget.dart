import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

class FoodPriceWidget extends StatelessWidget {
  final ProductData product;
  final Stock? stock;

  const FoodPriceWidget({super.key, required this.product, this.stock});

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock =
        stock?.quantity == null ||
        (stock?.quantity ?? 0) < (product.minQty ?? 0);
    final bool hasDiscount = isOutOfStock
        ? false
        : (stock?.discount != null && (stock?.discount ?? 0) > 0);
    return isOutOfStock
        ? Text(
            AppHelpers.getTranslation(TrKeys.outOfStock),
            style: AppStyle.interSemi(
              size: 11.sp,
              color: AppStyle.red,
              letterSpacing: -0.3,
            ),
          )
        : (hasDiscount
              ? Row(
                  children: [
                    Text(
                      AppHelpers.numberFormat(
                        number: (stock?.price ?? 0) + (stock?.tax ?? 0),
                      ),
                      style: AppStyle.interSemi(
                        size: 14.sp,
                        color: AppStyle.blackColor,
                        letterSpacing: -0.3,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    10.horizontalSpace,
                    Container(
                      padding: REdgeInsets.only(
                        top: 4,
                        bottom: 4,
                        left: 4,
                        right: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.r),
                        color: AppStyle.redBg,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Container(
                            width: 20.r,
                            height: 20.r,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppStyle.red,
                            ),
                            child: Icon(
                              Remix.percent_fill,
                              size: 12.r,
                              color: AppStyle.white,
                            ),
                          ),
                          8.horizontalSpace,
                          Text(
                            AppHelpers.numberFormat(
                              number: stock?.totalPrice ?? 0,
                            ),
                            style: AppStyle.interSemi(
                              size: 14.sp,
                              color: AppStyle.blackColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Text(
                  AppHelpers.numberFormat(number: stock?.totalPrice ?? 0),
                  style: AppStyle.interSemi(
                    size: 14.sp,
                    color: AppStyle.blackColor,
                    letterSpacing: -0.3,
                  ),
                ));
  }
}
