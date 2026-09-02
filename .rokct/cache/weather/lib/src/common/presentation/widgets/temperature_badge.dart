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
