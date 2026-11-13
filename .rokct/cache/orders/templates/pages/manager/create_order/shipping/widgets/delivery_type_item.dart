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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';

class DeliveryTypeItem extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String desc;
  final bool isActive;
  final VoidCallback onTap;

  const DeliveryTypeItem({
    super.key,
    required this.iconData,
    required this.title,
    required this.desc,
    required this.isActive,
    required this.onTap,
  }) ;

  @override
  Widget build(BuildContext context) {
    final Color ink = AppStyle.inkFor(Theme.of(context).brightness);
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isActive
                  ? AppStyle.primary
                  : AppStyle.strokeFor(Theme.of(context).brightness),
            ),
          ),
          padding: REdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppStyle.blackColor : AppStyle.transparent,
                  border: Border.all(color: isActive ? AppStyle.blackColor : ink),
                ),
                padding: EdgeInsets.all(10.r),
                child: Center(
                  child: Icon(
                    iconData,
                    color: isActive ? AppStyle.primary : ink,
                  ),
                ),
              ),
              10.horizontalSpace,
              // Expanded so a long localized line wraps inside the row
              // instead of overflowing it (RenderFlex stripes on phones).
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interSemi(
                      size: 14.sp,
                      color: ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(
                      size: 12.sp,
                      color: ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
