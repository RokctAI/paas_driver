// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class StatisticsItem extends StatelessWidget {
  final String title;
  final String count;
  final String percentage;
  final Color bgColor;
  final Color textColor;
  final Color iconColor;

  const StatisticsItem(
      {super.key,
      required this.title,
      required this.count,
      required this.percentage,
      required this.bgColor,
      required this.textColor,
      required this.iconColor});

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
            style: AppStyle.interNormal(
                size: 12, color: textColor, letterSpacing: -0.3),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                count,
                style: AppStyle.interSemi(
                    size: 14, color: textColor, letterSpacing: -0.6),
              ),
              Container(
                width: 6.r,
                height: 6.r,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: iconColor),
              ),
              Text(
                percentage,
                style: AppStyle.interSemi(
                    size: 14, color: textColor, letterSpacing: -0.6),
              ),
            ],
          )
        ],
      ),
    );
  }
}
