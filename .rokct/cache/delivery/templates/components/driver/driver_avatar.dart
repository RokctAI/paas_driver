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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/helper/common_image.dart';

class DriverAvatar extends StatelessWidget {
  final String? imageUrl;
  final num? rate;

  const DriverAvatar({super.key, this.imageUrl, required this.rate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70.r,
      child: Stack(
        children: [
          Container(
            height: 50.r,
            width: 50.r,
            decoration: const BoxDecoration(
              color: AppStyle.white,
              shape: BoxShape.circle,
            ),
            padding: REdgeInsets.all(2),
            child: ClipOval(child: CommonImage(url: imageUrl)),
          ),
          Positioned(
            top: 40.h,
            left: 2.w,
            child: Container(
              decoration: BoxDecoration(
                color: AppStyle.pendingDark,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppStyle.white, width: 2),
              ),
              padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 6.w),
              child: Row(
                children: [
                  Icon(
                    Remix.star_smile_fill,
                    color: AppStyle.white,
                    size: 12.r,
                  ),
                  Text(
                    double.parse((rate ?? 0.0).toString()).toStringAsFixed(2),
                    style: AppStyle.interNormal(
                      size: 10.sp,
                      color: AppStyle.white,
                      letterSpacing: -0.26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
