import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../component/components.dart';
import '../../../styles/style.dart';

class SectionsItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SectionsItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Style.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              Icon(icon),
              16.horizontalSpace,
              Text(
                title,
                style: Style.interRegular(size: 16.sp, color: Style.black),
              ),
              const Spacer(),
              const Icon(
                FlutterRemix.arrow_right_s_line,
                color: Style.tabBarBorderColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
