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
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class ProfileItem extends StatelessWidget {
  final String title;
  final String? count;
  final IconData icon;
  final bool isCount;
  final bool isLtr;
  final VoidCallback onTap;

  const ProfileItem({
    super.key,
    required this.title,
    required this.icon,
    this.isCount = false,
    this.count,
    required this.onTap,
    required this.isLtr,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationButtonEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 8.h),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon),
                    14.horizontalSpace,
                    Text(
                      title,
                      style: AppStyle.interNormal(
                        size: 14,
                        color: AppStyle.black,
                      ),
                    ),
                    12.horizontalSpace,
                    isCount
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 5.h,
                              horizontal: 14.w,
                            ),
                            decoration: BoxDecoration(
                              color: AppStyle.primary,
                              borderRadius: BorderRadius.all(
                                Radius.circular(100.r),
                              ),
                            ),
                            child: Text(
                              count ?? '',
                              style: AppStyle.interNormal(
                                size: 14,
                                color: AppStyle.black,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                Icon(
                  isLtr
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_left,
                  color: AppStyle.arrowRightProfileButton,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
