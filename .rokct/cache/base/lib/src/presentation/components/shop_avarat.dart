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
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

// ignore: must_be_immutable
class ShopAvatar extends StatelessWidget {
  final String shopImage;
  final double size;
  final double padding;
  final double radius;
  Color bgColor;

  ShopAvatar({
    super.key,
    required this.shopImage,
    required this.size,
    required this.padding,
    this.bgColor = AppStyle.whiteWithOpacity,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      padding: EdgeInsets.all(padding.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: CustomNetworkImage(
        url: shopImage,
        height: size.r,
        width: size.r,
        radius: size.r / 2,
      ),
    );
  }
}
