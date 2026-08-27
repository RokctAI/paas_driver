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
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class ShopTabBarItem extends StatelessWidget {
  final String title;
  final String image;
  final CategoryData? category;
  final bool isActive;
  final VoidCallback? onTap;

  const ShopTabBarItem({
    super.key,
    this.category,
    required this.isActive,
    this.onTap,
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap?.call();
      },
      child: AnimationButtonEffect(
        child: AnimatedContainer(
          height: 46.r,
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isActive ? AppStyle.primary : AppStyle.cardDark,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: AppStyle.white.withOpacity(0.07),
                spreadRadius: 0,
                blurRadius: 2,
                offset: const Offset(0, 1), // changes position of shadow
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 18.w),
          margin: EdgeInsets.only(right: 9.w, top: 24.h),
          child: Row(
            children: [
              if (category?.img?.isNotEmpty ?? false)
                Padding(
                  padding: EdgeInsets.only(right: 6.r),
                  child: CustomNetworkImage(
                    url: category?.img ?? image,
                    height: 42,
                    width: 42,
                    radius: 2,
                  ),
                ),
              Text(
                category?.translation?.title ?? title,
                style: AppStyle.interNormal(
                  size: 13,
                  color: isActive ? AppStyle.black : AppStyle.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
