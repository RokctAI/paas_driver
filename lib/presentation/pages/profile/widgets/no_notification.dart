import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../infrastructure/services/services.dart';
import '../../../styles/style.dart';

class NoNotification extends StatelessWidget {
  const NoNotification({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Style.borderColor),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 40.w) / 2,
            child: Text(
              AppHelpers.getTranslation(TrKeys.noNotices),
              style: Style.interRegular(size: 16.sp, letterSpacing: -0.3),
            ),
          ),
          Expanded(child: Image.asset(AppAssets.pngNoNotification))
        ],
      ),
    );
  }
}
