// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
//import '../../../infrastructure/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class RatingBadge extends StatelessWidget {
  final ShopData shop;
  final double? bottom;
  final double? left;
  final double? right;
  final double? top;
  final bool isText;

  const RatingBadge({
    super.key,
    required this.shop,
    this.bottom,
    this.left,
    this.right,
    this.top,
    this.isText = true,
  });

  @override
  Widget build(BuildContext context) {
    final double rating = double.tryParse(shop.avgRate ?? '0') ?? 0;
    final int filledStars = rating.floor().clamp(0, 5);

    return Positioned(
      //bottom: 20.h,
      bottom: bottom ?? 50.h,
      left: left,
      right: right ?? 15.w,
      top: top,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isText) ...[
                  Text(
                    AppHelpers.reviewText(double.tryParse(shop.avgRate ?? '0')),
                    style: AppStyle.interNormal(
                      color: AppStyle.white,
                      size: 12,
                    ),
                  ),
                  8.horizontalSpace,
                ],
                Row(
                  children: List.generate(
                    5,
                    (index) => SvgPicture.asset(
                      "assets/svgs/star.svg",
                      height: 12.r,
                      colorFilter: ColorFilter.mode(
                        index < filledStars
                            ? AppStyle.starColor
                            : AppStyle.white.withOpacity(0.3),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
