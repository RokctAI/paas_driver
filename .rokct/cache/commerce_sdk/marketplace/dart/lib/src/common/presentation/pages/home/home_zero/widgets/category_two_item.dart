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
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CategoryTwoItem extends StatelessWidget {
  final String image;
  final String title;
  final int index;
  final VoidCallback onTap;
  final bool isActive;

  const CategoryTwoItem({
    super.key,
    required this.image,
    required this.title,
    required this.index,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: index == 1 ? 4.r : 0, right: 8.r),
          width: 64.r,
          height: 100.r,
          padding: REdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(70.r)),
            color: isActive ? AppStyle.primary : AppStyle.white,
            boxShadow: const [
              BoxShadow(
                color: AppStyle.shadow,
                blurRadius: 15,
                offset: Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24.r),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppStyle.bgGrey,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: CustomNetworkImage(
                    fit: BoxFit.contain,
                    url: image,
                    height: 48.r,
                    width: 48.r,
                    radius: 24.r,
                  ),
                ),
                8.verticalSpace,
                SizedBox(
                  width: 62.w,
                  child: Text(
                    title,
                    style: AppStyle.interNormal(
                      size: 12,
                      color: AppStyle.black,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
