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

import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// Ported from pos main's
/// `weather/components/badges/temperature_badge.dart`.
class TemperatureBadge extends StatelessWidget {
  final int temperature;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final double borderWidth;
  final Color? backgroundColor;
  final String? suffix;
  final bool showShadow;

  const TemperatureBadge({
    super.key,
    required this.temperature,
    this.fontSize = 12.0,
    this.padding,
    this.borderWidth = 1.5,
    this.backgroundColor,
    this.suffix,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 6.sp, vertical: 3.sp),
      decoration: BoxDecoration(
        // Inverse chip: ink-colored pill with surface-colored text/ring, so it
        // flips with the theme (white pill on dark mode, dark pill on light).
        color: backgroundColor ?? AppStyle.textPrimary,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppStyle.cardDark, width: borderWidth),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppStyle.blackColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        '$temperature${suffix ?? '°'}',
        style: TextStyle(
          color: AppStyle.cardDark,
          fontSize: fontSize.sp,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
