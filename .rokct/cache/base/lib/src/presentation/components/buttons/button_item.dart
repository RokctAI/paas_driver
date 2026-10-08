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
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect2.dart';
import 'package:base_sdk/src/presentation/components/custom_toggle2.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart'; // Import the AppStyle class

class ButtonItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? selectValue;
  final String? onTitle;
  final String? offTitle;
  final VoidCallback onTap;
  final bool isLtr;
  final bool? value;

  const ButtonItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selectValue,
    this.value,
    this.onTitle,
    this.offTitle,
    required this.isLtr,
  });

  @override
  Widget build(BuildContext context) {
    // The mode comes from the inherited theme, not from the app-wide
    // AppStyle.isDark static (Ray, 2026-09-19: "glance doesnt change test
    // immediately untill you come back if you switched theme mode" - the
    // same defect, found here by the fleet audit that followed). A static
    // is not an inherited widget, so a mode flip scheduled no rebuild of
    // this widget and it kept the previous mode's colours until something
    // else happened to rebuild it. The colours come from AppStyle's
    // explicit-brightness seams, which name the same two values their
    // mode-resolving getters resolve between.
    final Brightness brightness = Theme.of(context).brightness;

    return ButtonEffectAnimation(
      disabled: value == null,
      onTap: value == null ? onTap : null,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.r, vertical: 4.r),
        decoration: BoxDecoration(
          color: AppStyle.cardFor(brightness),
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(20.r),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppStyle.inkFor(brightness),
            ),
            SizedBox(width: 12.r), // Replace 12.horizontalSpace with SizedBox
            Text(
              title,
              style: AppStyle.interNormal(
                color: AppStyle.inkFor(brightness),
                size: 16,
              ),
            ),
            const Spacer(),
            Text(
              selectValue ?? "",
              style: AppStyle.interNormal(
                color: AppStyle.inkFor(brightness),
                size: 12,
              ),
            ),
            if (value == null)
              Icon(
                isLtr ? Remix.arrow_right_line : Remix.arrow_left_line,
                color: AppStyle.inkFor(brightness),
              ),
            if (value != null)
              CustomToggle(
                offTitle: offTitle,
                onTitle: onTitle,
                isOnline: value ?? false,
                onChange: (s) {
                  onTap();
                },
                backgroundColor:
                    AppStyle.red, // Provide a color for backgroundColor
                newBoxColor: AppStyle.white, // Provide a color for newBoxColor
                socialButtonColor:
                    AppStyle.blue, // Provide a color for socialButtonColor
                textColor: AppStyle.black, // Provide a color for textColor
              ),
          ],
        ),
      ),
    );
  }
}
