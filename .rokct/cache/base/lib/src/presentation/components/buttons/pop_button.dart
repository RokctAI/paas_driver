// Copyright (c) 2026 RokctAI
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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:remixicon/remixicon.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/blur_wrap.dart';

class PopButton extends StatelessWidget {
  final VoidCallback? onTap;

  /// Optional Hero tag so a page's back/pop pill can pair with a FAB on the
  /// launching page (e.g. merchants_sdk main_page's add-order Hero uses
  /// 'heroTagAddOrderButton', and orders_sdk's create-order pages pass the
  /// same literal here).
  final String? heroTag;

  const PopButton({super.key, this.onTap, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);
    if (heroTag != null) {
      return Hero(tag: heroTag!, child: button);
    }
    return button;
  }

  Widget _buildButton(BuildContext context) {
    return BlurWrap(
      radius: BorderRadius.circular(100.r),
      child: GestureDetector(
        onTap: onTap ?? () => Navigator.pop(context),
        child: Container(
          constraints: BoxConstraints(minWidth: 100.w),
          height: 48.r,
          padding: EdgeInsets.symmetric(horizontal: 16.r),
          decoration: BoxDecoration(
            color: AppStyle.bottomNavigationBarColor.withOpacity(0.3),
            borderRadius: BorderRadius.all(Radius.circular(100.r)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Remix.arrow_left_wide_fill,
                    size: 20.r,
                    color: AppStyle.white,
                  ),
                  4.horizontalSpace,
                  Column(
                    children: [
                      Text(
                        AppHelpers.getTranslation(TrKeys.back),
                        style: TextStyle(
                          color: AppStyle.white,
                          fontSize: 12.sp,
                        ),
                      ),
                      3.verticalSpace,
                      Container(
                        height: 4.h,
                        width: 24.w,
                        decoration: BoxDecoration(
                          color: AppStyle.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(100.r),
                            topRight: Radius.circular(100.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
