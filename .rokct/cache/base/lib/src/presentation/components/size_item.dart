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
import 'package:base_sdk/src/services/vibration.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class SizeItem extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final String title;

  const SizeItem({
    super.key,
    required this.onTap,
    required this.isActive,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // The mode comes from the inherited theme, not from the app-wide
    // AppStyle.isDark static (Ray, 2026-09-19: "glance doesnt change test
    // immediately untill you come back if you switched theme mode" - the
    // same defect, found here by the fleet audit that followed). A static
    // is not an inherited widget, so a mode flip scheduled no rebuild of
    // this widget and it kept the previous mode's colours until something
    // else happened to rebuild it.
    final Brightness brightness = Theme.of(context).brightness;

    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: GestureDetector(
        onTap: () {
          onTap();
          Vibrate.feedback(FeedbackType.selection);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppStyle.cardFor(brightness),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 18.r,
                    height: 18.r,
                    decoration: BoxDecoration(
                      color: isActive ? AppStyle.primary : AppStyle.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? AppStyle.black : AppStyle.textGrey,
                        width: isActive ? 4.r : 2.r,
                      ),
                    ),
                  ),
                  16.horizontalSpace,
                  Text(
                    title,
                    style: AppStyle.interNormal(
                      size: 16,
                      color: AppStyle.inkFor(brightness),
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              Divider(color: AppStyle.textGrey.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
