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

import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';

class CustomButton extends StatelessWidget {
  final Icon? icon;
  final String title;
  final bool isLoading;
  final Function()? onPressed;
  /// Defaults to [AppStyle.primary] when null. Cannot be a default
  /// parameter value: primary is now an injectable getter, not a compile-
  /// time constant, and default values must be const.
  final Color? background;
  final Color borderColor;
  final Color textColor;
  final double weight;
  final double radius;

  const CustomButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.isLoading = false,
    this.background,
    this.textColor = AppStyle.black,
    this.weight = double.infinity,
    this.radius = 8,
    this.icon,
    this.borderColor = AppStyle.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationButtonEffect(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          side: BorderSide(
            color:
                borderColor == AppStyle.transparent
                    ? (background ?? AppStyle.primary)
                    : borderColor,
            width: 2.r,
          ),
          elevation: 0,
          shadowColor: AppStyle.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.r),
          ),
          minimumSize: Size(weight, 50.h),
          backgroundColor: background ?? AppStyle.primary,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2.r,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon == null
                      ? const SizedBox()
                      : Row(children: [icon!, 10.horizontalSpace]),
                  Text(
                    title,
                    style: AppStyle.interNormal(
                      size: 15,
                      color: textColor,
                      letterSpacing: -14 * 0.01,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
