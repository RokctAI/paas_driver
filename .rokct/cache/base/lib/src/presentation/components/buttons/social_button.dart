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

class SocialButton extends StatelessWidget {
  final IconData iconData;
  final Function() onPressed;
  final String title;

  const SocialButton({
    super.key,
    required this.iconData,
    required this.onPressed,
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
    // else happened to rebuild it. The colours come from AppStyle's
    // explicit-brightness seams, which name the same two values their
    // mode-resolving getters resolve between.
    final Brightness brightness = Theme.of(context).brightness;

    return AnimationButtonEffect(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppStyle.cardAltFor(brightness),
          side: BorderSide(color: AppStyle.strokeFor(brightness), width: 0.5),
          minimumSize: Size(96.r, 36.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(iconData, color: AppStyle.inkFor(brightness), size: 16.r),
            8.horizontalSpace,
            Text(
              title,
              style: AppStyle.interNormal(size: 12, color: AppStyle.inkFor(brightness)),
            ),
          ],
        ),
      ),
    );
  }
}
