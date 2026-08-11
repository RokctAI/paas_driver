import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class TitleAndPrice extends StatelessWidget {
  final String title;
  final String rightTitle;
  final TextStyle textStyle;

  const TitleAndPrice({
    super.key,
    required this.title,
    required this.rightTitle,
    required this.textStyle,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppStyle.interRegular(
              size: 16.sp,
              color: AppStyle.blackColor,
              letterSpacing: -0.3,
            ),
          ),
          Text(rightTitle, style: textStyle),
        ],
      ),
    );
  }
}
