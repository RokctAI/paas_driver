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
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:lottie/lottie.dart';

class EmptyBadge extends StatelessWidget {
  final String imagePath;
  final String titleText;
  final String subtitleText;
  final String? linkText;
  final GestureTapCallback? onLinkTap;

  EmptyBadge({
    super.key,
    this.imagePath = 'assets/lottie/notification_empty.json',
    String? titleText,
    String? subtitleText,
    this.linkText,
    this.onLinkTap,
  })  : titleText = titleText ?? AppHelpers.getTranslation(TrKeys.nothingFound),
        subtitleText =
            subtitleText ?? AppHelpers.getTranslation(TrKeys.trySearchingAgain);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //32.verticalSpace,
        Lottie.asset(imagePath, height: 200),
        Text(titleText, style: AppStyle.interSemi(size: 18.sp)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: subtitleText,
              style: AppStyle.interRegular(size: 14.sp),
              children: linkText != null && onLinkTap != null
                  ? [
                      TextSpan(
                        text: ' $linkText',
                        style: TextStyle(
                          color: AppStyle.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                      ),
                    ]
                  : [],
            ),
          ),
        ),
      ],
    );
  }
}
