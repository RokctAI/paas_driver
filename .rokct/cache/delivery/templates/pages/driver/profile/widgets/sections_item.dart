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
import 'package:${package}/presentation/component/buttons/buttons_bouncing_effect.dart';

class SectionsItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SectionsItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              Icon(icon),
              16.horizontalSpace,
              Text(
                title,
                style: AppStyle.interRegular(
                  size: 16.sp,
                  color: AppStyle.black,
                ),
              ),
              const Spacer(),
              const Icon(
                Remix.arrow_right_s_line,
                color: AppStyle.tabBarBorderColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
