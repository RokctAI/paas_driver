import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:${package}/presentation/theme/theme.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class StatisticsItem extends StatelessWidget {
  final String title;
  final int count;
  final double? percentage;
  final Color bgColor;
  final Color textColor;
  final Color iconColor;

  const StatisticsItem({
    super.key,
    required this.title,
    required this.count,
    required this.bgColor,
    required this.textColor,
    required this.iconColor,
    this.percentage,
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
      padding: REdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyle.interNormal(
              size: 12,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                '$count',
                style: AppStyle.interSemi(
                  size: 14,
                  color: textColor,
                  letterSpacing: -0.6,
                ),
              ),
              if (percentage != null)
                Row(
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      margin: REdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor,
                      ),
                    ),
                    Text(
                      '${percentage?.toStringAsFixed(1)}%',
                      style: AppStyle.interSemi(
                        size: 14,
                        color: textColor,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

