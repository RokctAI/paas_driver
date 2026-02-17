import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';

import '../../infrastructure/services/app_helpers.dart';
import '../../infrastructure/services/tr_keys.dart';
import '../styles/style.dart';

class ProductItem extends StatelessWidget {
  final Product? product;
  final num? amount;
  final String price;

  const ProductItem({
    super.key,
    required this.product,
    required this.amount,
    required this.price,
  });

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
                    style: Style.interSemi(size: 14.sp, color: Style.black),
                  ),
                  4.verticalSpace,
                  Text(
                    "${AppHelpers.getTranslation(TrKeys.amount)} — ${(amount ?? 1) * (product?.interval ?? 1)} ${(product?.unit?.translation?.title ?? "")}",
                    style: Style.interRegular(size: 14.sp, color: Style.black),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: Style.interSemi(size: 14.sp, color: Style.black),
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
                        text: "${AppHelpers.getTranslation(TrKeys.sideDish)}:",
                        style: Style.interSemi(size: 14.sp, color: Style.black),
                        children: [
                          TextSpan(
                            text: product?.translation?.description ?? "",
                            style: Style.interRegular(
                              size: 14.sp,
                              color: Style.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
