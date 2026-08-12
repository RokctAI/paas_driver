import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/helper/common_image.dart';

class DriverAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String desc;

  const DriverAvatar({
    super.key,
    required this.name,
    required this.desc,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 50.r,
          width: 50.r,
          child: CommonImage(url: imageUrl, radius: 25),
        ),
        12.horizontalSpace,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: AppStyle.interRegular(size: 14.sp, color: AppStyle.blackColor),
            ),
            4.verticalSpace,
            Text(
              desc,
              style: AppStyle.interNormal(size: 12.sp, color: AppStyle.blackColor),
            )
          ],
        ),
      ],
    );
  }
}
