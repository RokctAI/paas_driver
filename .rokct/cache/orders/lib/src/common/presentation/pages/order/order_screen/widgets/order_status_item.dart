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

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class OrderStatusItem extends StatelessWidget {
  final Widget icon;
  final bool isActive;
  final bool isProgress;
  /// Defaults to [AppStyle.primary] when null (a getter since core #105, so
  /// it cannot be a const default value).
  final Color? bgColor;

  const OrderStatusItem({
    super.key,
    required this.icon,
    required this.isActive,
    required this.isProgress,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: isActive ? (bgColor ?? AppStyle.primary) : AppStyle.white,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Positioned(top: 8.h, left: 10.w, child: icon),
          isProgress
              ? SvgPicture.asset(
                  "assets/svgs/orderTime.svg",
                  color: AppStyle.primary,
                  width: 36.w,
                  height: 36.h,
                )
              : SizedBox(width: 36.w, height: 36.h),
        ],
      ),
    );
  }
}
