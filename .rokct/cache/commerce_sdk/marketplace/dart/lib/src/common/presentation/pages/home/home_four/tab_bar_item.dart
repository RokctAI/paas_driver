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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';

class CategoryBarItem extends StatelessWidget {
  final String image;
  final String title;
  final int index;
  final VoidCallback onTap;
  final bool isActive;

  const CategoryBarItem({
    super.key,
    required this.image,
    required this.title,
    required this.index,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 100.r : 85.r,
      height: isActive ? 100.r : 85.r,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        //  color: isActive ? AppStyle.brandGreen : AppStyle.white),
        //color: isActive ? AppStyle.brandGreen : AppStyle.brandGreen.withOpacity(0.06),
        color: isActive ? AppStyle.primary : AppStyle.transparent,
        // border: Border.all(color: isActive ? AppStyle.transparent : AppStyle.brandGreen, ), // added border
      ), //changed
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomNetworkImage(
              fit: BoxFit.contain,
              url: image,
              height: isActive ? 48 : 48.r,
              width: isActive ? 48 : 48.r,
              radius: 0,
              color: isActive
                  ? AppStyle.white
                  : AppStyle.primary, // Changed added
            ),
            4.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.r),
              child: Text(
                title,
                style: AppStyle.interNormal(
                  // size: isActive ? 12 : 10,
                  size: 12,
                  // color: AppStyle.black,
                  color: isActive ? AppStyle.white : AppStyle.primary, //changed
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
