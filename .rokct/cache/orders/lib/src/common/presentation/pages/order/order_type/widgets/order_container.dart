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

class OrderContainer extends StatelessWidget {
  final Widget icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const OrderContainer({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyle.bgGrey,
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Row(
          children: [
            icon,
            14.horizontalSpace,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.textGrey,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width - 164.w,
                  child: Text(
                    description,
                    style: AppStyle.interBold(size: 14, color: AppStyle.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_right, size: 21.r),
          ],
        ),
      ),
    );
  }
}
