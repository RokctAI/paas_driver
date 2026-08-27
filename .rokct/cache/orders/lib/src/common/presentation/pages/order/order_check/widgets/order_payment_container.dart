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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class OrderPaymentContainer extends ConsumerWidget {
  final Widget icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;
  final bool isPayFast;

  const OrderPaymentContainer({
    super.key,
    required this.icon,
    required this.title,
    this.isActive = false,
    required this.onTap,
    this.isPayFast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        onTap();

        // If this is PayFast and it's been selected, start preloading the WebView
        if (isPayFast && !isActive) {
          // We'll implement this logic in the payment selection flow
        }
      },
      child: Container(
        width: (MediaQuery.sizeOf(context).width - 42) / 2,
        height: 120.h,
        decoration: BoxDecoration(
          color: AppStyle.bgGrey,
          borderRadius: BorderRadius.all(Radius.circular(10.r)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isActive ? AppStyle.black : AppStyle.white,
                borderRadius: BorderRadius.all(Radius.circular(8.r)),
              ),
              padding: EdgeInsets.all(8.r),
              child: icon,
            ),
            8.verticalSpace,
            Text(
              AppHelpers.getTranslation(title),
              style: AppStyle.interSemi(size: 13, color: AppStyle.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
