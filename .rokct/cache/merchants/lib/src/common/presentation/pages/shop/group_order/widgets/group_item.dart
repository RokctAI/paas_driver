// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
