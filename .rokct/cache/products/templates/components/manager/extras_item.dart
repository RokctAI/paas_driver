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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';

/// An extras-group chip of the approved stocks pane (frame 35b: Size /
/// Sauce / Cheese, checked = in use): each checked group's value
/// combinations make one stock row. Same tap behaviour as shipped — toggle
/// plus the group-extras sheet — in the approved chip dress.
class ExtrasItem extends StatelessWidget {
  final SellerExtrasGroup extras;
  final Function()? onTap;
  final bool isLast;

  const ExtrasItem({
    super.key,
    required this.extras,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool checked = extras.isChecked ?? false;
    return ButtonsBouncingEffect(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: REdgeInsets.only(right: 8, top: 8, bottom: 8),
          padding: REdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100.r),
            color: AppStyle.transparent,
            border: Border.all(
              color: checked ? AppStyle.primary : AppStyle.strokeDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                checked
                    ? Remix.checkbox_circle_fill
                    : Remix.checkbox_blank_circle_line,
                color: checked ? AppStyle.primary : AppStyle.textDarkFaint,
                size: 18.r,
              ),
              6.horizontalSpace,
              Text(
                '${extras.translation?.title}',
                style: AppStyle.interSemi(
                  size: 13.sp,
                  letterSpacing: -0.3,
                  color: checked ? AppStyle.primary : AppStyle.textDarkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
