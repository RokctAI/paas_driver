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
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect2.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// Navigation row for profile sections: leading icon, title, optional
/// subtitle, optional trailing widget (chevron by default), tap action.
class ProfileNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const ProfileNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonEffectAnimation(
      disabled: false,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 12.r),
        child: Row(
          children: [
            Icon(icon, size: 22.sp, color: AppStyle.textPrimary),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyle.interSemi(
                      size: 15.sp,
                      color: AppStyle.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    2.verticalSpace,
                    Text(
                      subtitle!,
                      style: AppStyle.interNormal(
                        size: 13.sp,
                        color: AppStyle.textDarkSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            8.horizontalSpace,
            trailing ??
                Icon(
                  Remix.arrow_right_s_line,
                  size: 20.sp,
                  color: AppStyle.textDarkSecondary,
                ),
          ],
        ),
      ),
    );
  }
}
