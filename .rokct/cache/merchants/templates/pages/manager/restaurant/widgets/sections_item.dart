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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

// Ported from paas_manager lib/presentation/pages/restaurant/widgets/
// sections_item.dart (styles repointed to base_sdk's AppStyle).
//
// [subtitle] (optional) renders a small grey glance line under the title —
// added for the approved PRODUCTIVITY gate row (frame 7e, chip 391, Ray
// 2026-08-29 15:41Z), whose Tasks row carries open/due counts. Rows
// without a subtitle are byte-identical to the original single-line
// layout.
class SectionsItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SectionsItem({
    super.key,
    required this.title,
    this.subtitle,
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
            subtitle == null
                ? Text(
                    title,
                    style: AppStyle.interRegular(
                      size: 16.sp,
                      color: AppStyle.blackColor,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppStyle.interRegular(
                          size: 16.sp,
                          color: AppStyle.blackColor,
                        ),
                      ),
                      2.verticalSpace,
                      Text(
                        subtitle!,
                        style: AppStyle.interRegular(
                          size: 12.sp,
                          color: AppStyle.textGrey,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
