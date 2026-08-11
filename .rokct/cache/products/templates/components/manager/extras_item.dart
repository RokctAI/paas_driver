import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';

class ExtrasItem extends StatelessWidget {
  final SellerExtrasGroup extras;
  final Function()? onTap;
  final bool isLast;

  const ExtrasItem({
    super.key,
    required this.extras,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: AppStyle.transparent,
          padding: REdgeInsets.symmetric(vertical: 16),
          margin: REdgeInsets.only(right: 14),
          child: Row(
            children: [
              Icon(
                (extras.isChecked ?? false)
                    ? FlutterRemix.checkbox_circle_fill
                    : FlutterRemix.checkbox_blank_circle_line,
                color: (extras.isChecked ?? false)
                    ? AppStyle.primary
                    : AppStyle.blackColor,
                size: 24.r,
              ),
              4.horizontalSpace,
              Text(
                '${extras.translation?.title}',
                style: AppStyle.interSemi(size: 14.sp, letterSpacing: -0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
