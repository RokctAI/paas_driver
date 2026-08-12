import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ProductItem extends StatelessWidget {
  final Product? product;
  final num? amount;
  final String price;

  const ProductItem(
      {super.key,
      required this.product,
      required this.amount,
      required this.price});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.translation?.title ?? "",
                    style: AppStyle.interSemi(size: 14.sp, color: AppStyle.black),
                  ),
                  4.verticalSpace,
                  Text(
                    "${AppHelpers.getTranslation(TrKeys.amount)} — ${(amount ?? 1) * (product?.interval ?? 1)} ${(product?.unit?.translation?.title ?? "")}",
                    style: AppStyle.interRegular(size: 14.sp, color: AppStyle.black),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: AppStyle.interSemi(size: 14.sp, color: AppStyle.black),
            ),
          ],
        ),
        product?.translation?.description != null
            ? Column(
                children: [
                  16.verticalSpace,
                  SizedBox(
                    width: 200.w,
                    child: RichText(
                      text: TextSpan(
                          text:
                              "${AppHelpers.getTranslation(TrKeys.sideDish)}:",
                          style:
                              AppStyle.interSemi(size: 14.sp, color: AppStyle.black),
                          children: [
                            TextSpan(
                              text: product?.translation?.description ?? "",
                              style: AppStyle.interRegular(
                                  size: 14.sp, color: AppStyle.black),
                            ),
                          ]),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
