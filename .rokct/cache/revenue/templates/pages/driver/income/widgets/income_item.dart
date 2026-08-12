import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class IncomeItem extends StatelessWidget {
  final String title;
  final String price;
  final bool isBlack;

  const IncomeItem(
      {super.key,
      required this.title,
      required this.price,
      this.isBlack = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: isBlack ? AppStyle.blackColor : AppStyle.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppStyle.interNormal(
                size: 14,
                letterSpacing: -0.3,
                color: isBlack ? AppStyle.white : AppStyle.blackColor),
          ),
          6.horizontalSpace,
          Expanded(
            child: Text(
              price,
              style: AppStyle.interSemi(
                size: 14,
                letterSpacing: -0.3,
                color: isBlack ? AppStyle.white : AppStyle.blackColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
