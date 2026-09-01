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
    return AnimationButtonEffect(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppStyle.cardDarkAlt,
          side: BorderSide(color: AppStyle.strokeDark, width: 0.5),
          minimumSize: Size(96.r, 36.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(iconData, color: AppStyle.textPrimary, size: 16.r),
            8.horizontalSpace,
            Text(
              title,
              style: AppStyle.interNormal(size: 12, color: AppStyle.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
