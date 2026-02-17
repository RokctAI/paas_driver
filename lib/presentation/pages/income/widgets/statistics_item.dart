import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../styles/style.dart';

class StatisticsItem extends StatelessWidget {
  final String title;
  final String count;
  final String percentage;
  final Color bgColor;
  final Color textColor;
  final Color iconColor;

  const StatisticsItem({
    super.key,
    required this.title,
    required this.count,
    required this.percentage,
    required this.bgColor,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88.h,
      width: (MediaQuery.sizeOf(context).width - 140.w) / 2,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.all(12.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Style.interNormal(
              size: 12.sp,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                count,
                style: Style.interSemi(
                  size: 14.sp,
                  color: textColor,
                  letterSpacing: -0.6,
                ),
              ),
              Container(
                width: 6.r,
                height: 6.r,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor,
                ),
              ),
              Text(
                percentage,
                style: Style.interSemi(
                  size: 14.sp,
                  color: textColor,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
