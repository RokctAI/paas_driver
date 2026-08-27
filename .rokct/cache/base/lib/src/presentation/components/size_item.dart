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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/vibration.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class SizeItem extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final String title;

  const SizeItem({
    super.key,
    required this.onTap,
    required this.isActive,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: GestureDetector(
        onTap: () {
          onTap();
          Vibrate.feedback(FeedbackType.selection);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppStyle.cardDark,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 18.r,
                    height: 18.r,
                    decoration: BoxDecoration(
                      color: isActive ? AppStyle.primary : AppStyle.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? AppStyle.black : AppStyle.textGrey,
                        width: isActive ? 4.r : 2.r,
                      ),
                    ),
                  ),
                  16.horizontalSpace,
                  Text(
                    title,
                    style: AppStyle.interNormal(
                      size: 16,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              Divider(color: AppStyle.textGrey.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
