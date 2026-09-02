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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class GroupItem extends StatelessWidget {
  final String name;
  final bool isChoosing;
  final num? price;
  final bool isDeleteButton;
  final VoidCallback onDelete;

  const GroupItem({
    super.key,
    required this.name,
    required this.price,
    required this.isChoosing,
    required this.onDelete,
    this.isDeleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.all(Radius.circular(10.h)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: const BoxDecoration(
                    color: AppStyle.bgGrey,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(6.r),
                  child: SvgPicture.asset("assets/svgs/avatar.svg"),
                ),
                10.horizontalSpace,
                Expanded(
                  child: Text(
                    name,
                    style: AppStyle.interNormal(
                      size: 14,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                "${isChoosing ? AppHelpers.getTranslation(TrKeys.choosing) : AppHelpers.getTranslation(TrKeys.done)} — ",
                style: AppStyle.interNormal(size: 14, color: AppStyle.textPrimary),
              ),
              Text(
                AppHelpers.numberFormat(number: price),
                style: AppStyle.interSemi(size: 14, color: AppStyle.textPrimary),
              ),
              isDeleteButton
                  ? GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        color: AppStyle.transparent,
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Icon(
                            Remix.close_fill,
                            size: 20.r,
                            color: AppStyle.textPrimary,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
