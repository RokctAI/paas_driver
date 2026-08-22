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
import 'package:base_sdk/src/presentation/components/blur_wrap.dart';
import 'package:base_sdk/src/presentation/components/helper/common_image.dart';

class ShopBorderedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double imageSize;
  final double borderRadius;
  final Color bgColor;

  const ShopBorderedAvatar({
    super.key,
    this.imageUrl,
    required this.size,
    required this.imageSize,
    required this.borderRadius,
    this.bgColor = AppStyle.bgGrey,
  });

  @override
  Widget build(BuildContext context) {
    return BlurWrap(
      radius: BorderRadius.circular(borderRadius.r),
      child: Container(
        width: size.r,
        height: size.r,
        color: bgColor,
        alignment: Alignment.center,
        child: CommonImage(
          url: imageUrl,
          width: imageSize,
          height: imageSize,
          radius: imageSize / 2,
        ),
      ),
    );
  }
}
