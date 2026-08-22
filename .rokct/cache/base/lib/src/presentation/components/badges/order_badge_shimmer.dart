// Copyright (c) 2026 RokctAI
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


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class OrderBadge extends StatelessWidget {
  final Color? imageColor;
  final Color? containerColor;
  final Color? textColor;

  const OrderBadge({
    super.key,
    this.imageColor,
    this.containerColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          //'assets/svgs/foodyman.svg', // Path to your updated SVG asset
          'assets/svgs/brand_logo_rounded.svg',
          height: 24.h, // Adjust height as needed using ScreenUtil
          width: 24.w, // Adjust width as needed using ScreenUtil
          colorFilter: imageColor != null
              ? ColorFilter.mode(imageColor!, BlendMode.colorDodge)
              : ColorFilter.mode(
                  AppStyle.primary,
                  BlendMode.colorDodge,
                ), // Use colorFilter to apply color to the SVG
        ),
        SizedBox(width: 5.w), // Adjust spacing as needed using ScreenUtil
        Container(
          height: 22.h, // Adjust height as needed using ScreenUtil
          decoration: BoxDecoration(
            color: containerColor ??
                AppStyle.primary, // Use customizable color with default
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(
                10.0,
              ), // Adjust top-right radius as needed
              bottomRight: Radius.circular(
                10.0,
              ), // Adjust bottom-right radius as needed
            ), // Adjust the radius as needed
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 5.w,
          ), // Adjust padding as needed using ScreenUtil
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppHelpers.getTranslation(
                  TrKeys.orderNow,
                ), // Make sure AppHelpers is imported and accessible
                style: AppStyle.interNoSemi(
                  size: 12,
                  color: textColor ??
                      AppStyle.white, // Use customizable color with default
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
