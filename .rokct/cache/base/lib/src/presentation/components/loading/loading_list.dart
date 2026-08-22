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

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class LoadingList extends StatelessWidget {
  final int itemCount;
  final int horizontalPadding;
  final int verticalPadding;
  final int itemBorderRadius;
  final int itemPadding;
  final int itemHeight;

  const LoadingList({
    super.key,
    this.itemCount = 10,
    this.horizontalPadding = 0,
    this.verticalPadding = 0,
    this.itemBorderRadius = 10,
    this.itemPadding = 10,
    this.itemHeight = 134,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: REdgeInsets.symmetric(
        horizontal: horizontalPadding.r,
        vertical: verticalPadding.r,
      ),
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight.h,
          margin: EdgeInsets.only(bottom: itemPadding.h),
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(itemBorderRadius.r),
          ),
        );
      },
    );
  }
}
