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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

class LoadingGrid extends StatelessWidget {
  final int itemCount;
  final int horizontalPadding;
  final int verticalPadding;
  final int itemBorderRadius;
  final int itemHeight;
  final int mainAxisSpacing;
  final int crossAxisCount;
  final int crossAxisSpacing;

  const LoadingGrid({
    super.key,
    this.itemCount = 10,
    this.horizontalPadding = 0,
    this.verticalPadding = 0,
    this.itemBorderRadius = 10,
    this.itemHeight = 134,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 6,
    this.crossAxisSpacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing.r,
          crossAxisSpacing: crossAxisSpacing.r,
          mainAxisExtent: itemHeight.r,
        ),
        itemCount: itemCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: REdgeInsets.symmetric(
          horizontal: horizontalPadding.r,
          vertical: verticalPadding.r,
        ),
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: AppConstants.animationDuration,
            columnCount: itemCount,
            child: ScaleAnimation(
              scale: 0.5,
              child: FadeInAnimation(
                child: Container(
                  height: itemHeight.h,
                  decoration: BoxDecoration(
                    color: AppStyle.cardDark,
                    borderRadius: BorderRadius.circular(itemBorderRadius.r),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
