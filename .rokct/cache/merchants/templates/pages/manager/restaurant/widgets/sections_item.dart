import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

// Ported from paas_manager lib/presentation/pages/restaurant/widgets/
// sections_item.dart (styles repointed to base_sdk's AppStyle).
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20.h),
        color: AppStyle.transparent,
        child: Row(
          children: [
            Icon(icon),
            16.horizontalSpace,
            Text(
              title,
              style: AppStyle.interRegular(
                size: 16.sp,
                color: AppStyle.blackColor,
              ),
            )
          ],
        ),
      ),
    );
  }
}
