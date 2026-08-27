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
    return ButtonEffectAnimation(
      disabled: value == null,
      onTap: value == null ? onTap : null,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.r, vertical: 4.r),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(20.r),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppStyle.textPrimary,
            ),
            SizedBox(width: 12.r), // Replace 12.horizontalSpace with SizedBox
            Text(
              title,
              style: AppStyle.interNormal(
                color: AppStyle.textPrimary,
                size: 16,
              ),
            ),
            const Spacer(),
            Text(
              selectValue ?? "",
              style: AppStyle.interNormal(
                color: AppStyle.textPrimary,
                size: 12,
              ),
            ),
            if (value == null)
              Icon(
                isLtr ? Remix.arrow_right_line : Remix.arrow_left_line,
                color: AppStyle.textPrimary,
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
