import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';

class PaymentItem extends StatelessWidget {
  final Payment payment;
  final bool isSelected;
  final bool isLast;
  final Function() onTap;

  const PaymentItem({
    super.key,
    required this.payment,
    required this.isSelected,
    required this.onTap,
    this.isLast = false,
  }) ;

  @override
  Widget build(BuildContext context) {
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? FlutterRemix.checkbox_circle_fill
                      : FlutterRemix.checkbox_circle_line,
                  size: 24.r,
                  color: isSelected ? AppStyle.primary : AppStyle.blackColor,
                ),
                14.horizontalSpace,
                Text(
                  '${toBeginningOfSentenceCase(payment.payment?.tag)}',
                  style: AppStyle.interSemi(size: 14.sp, letterSpacing: -0.3),
                ),
              ],
            ),
            if (!isLast)
              Column(
                children: [
                  14.verticalSpace,
                  Divider(
                    thickness: 1.r,
                    height: 1.r,
                    color: AppStyle.bgGrey,
                  ),
                  14.verticalSpace,
                ],
              ),
          ],
        ),
      ),
    );
  }
}
