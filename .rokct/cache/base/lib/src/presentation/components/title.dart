import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect2.dart';

class TitleWidget extends StatelessWidget {
  final String title;
  final String? subTitle;
  final VoidCallback? onTap;
  final Color titleColor;
  final bool isSale;

  const TitleWidget({
    super.key,
    required this.title,
    this.subTitle,
    this.onTap,
    required this.titleColor,
    this.isSale = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.r),
          child: Text(
            title,
            style: AppStyle.interNoSemi(color: titleColor, size: 22),
          ),
        ),
        if (isSale && AppHelpers.getType() != 3)
          Container(
            margin: EdgeInsets.only(left: 8.r),
            padding: EdgeInsets.symmetric(vertical: 4.r, horizontal: 8.r),
            decoration: BoxDecoration(
              color: AppStyle.red,
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Row(
              children: [
                Icon(
                  Remix.percent_fill,
                  color: AppStyle.white,
                  size: 14.r,
                ),
                4.horizontalSpace,
                Text(
                  AppHelpers.getTranslation(TrKeys.sale.toUpperCase()),
                  style: AppStyle.interNoSemi(color: AppStyle.white, size: 10),
                ),
              ],
            ),
          ),
        const Spacer(),
        if (subTitle != null)
          ButtonEffectAnimation(
            onTap: () {
              onTap?.call();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.r, horizontal: 16.r),
              child: Text(
                subTitle ?? "",
                style: AppStyle.interNormal(color: AppStyle.red, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}
