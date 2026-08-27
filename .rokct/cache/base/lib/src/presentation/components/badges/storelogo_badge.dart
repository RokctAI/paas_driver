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


import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/badge_item.dart';
import 'package:base_sdk/src/presentation/components/shop_avarat.dart';

class ShopBadge extends StatefulWidget {
  final ShopData shop;
  final double? bottom;
  final double? left;
  final double? right;
  final double? top;
  final double? iconSize;
  final double? containerHeight;
  final double? containerWidth;
  final double? fontSize;
  final int? maxTextLength;

  const ShopBadge({
    super.key,
    required this.shop,
    this.bottom,
    this.left,
    this.right,
    this.top,
    this.iconSize,
    this.containerHeight,
    this.containerWidth,
    this.fontSize,
    this.maxTextLength,
  });

  @override
  State<ShopBadge> createState() => _ShopBadgeState();
}

class _ShopBadgeState extends State<ShopBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top ?? 35.h,
      left: widget.left ?? 15.w,
      right: widget.right,
      bottom: widget.bottom,
      child: ClipRect(
        child: SlideTransition(
          position: _offsetAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                height: widget.containerHeight,
                width: widget.containerWidth,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShopAvatar(
                      radius: 20,
                      shopImage: widget.shop.logoImg ?? "",
                      size: widget.iconSize ?? 33,
                      padding: 0,
                      bgColor: AppStyle.transparent,
                    ),
                    SizedBox(width: 5.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              _truncateText(
                                widget.shop.translation?.title ?? "",
                              ),
                              style: AppStyle.interSemi(
                                size: widget.fontSize ?? 20,
                                color: AppStyle.white,
                              ),
                            ),
                            if (widget.shop.verify ?? false)
                              Padding(
                                padding: EdgeInsets.only(left: 4.r),
                                child: BadgeItem(
                                  color: AppStyle.white,
                                  size: widget.iconSize != null
                                      ? widget.iconSize! / 2
                                      : null,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _truncateText(String text) {
    final maxLength = widget.maxTextLength ?? 11;
    if (text.length > maxLength) {
      return text.substring(0, maxLength - 1);
    }
    return text;
  }
}
