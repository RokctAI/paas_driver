import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CustomAppBar extends StatelessWidget {
  final Widget child;
  final double height;
  final double bottomPadding;

  const CustomAppBar({
    super.key,
    required this.child,
    this.height = 110,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height.h,
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: REdgeInsets.only(left: 16, right: 16, bottom: bottomPadding),
          child: child,
        ),
      ),
    );
  }
}
