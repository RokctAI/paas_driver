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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class ResendButton extends StatelessWidget {
  final String title;
  final IconData iconData;
  final bool isTimeExpired;
  final bool isResending;
  final Function()? onPressed;

  const ResendButton({
    super.key,
    required this.title,
    this.iconData = Remix.refresh_line,
    this.isTimeExpired = false,
    this.isResending = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: AppStyle.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size(97.r, 46.r),
        backgroundColor: AppStyle.black,
      ),
      onPressed: onPressed,
      child: isTimeExpired
          ? isResending
              ? SizedBox(
                  width: 10.r,
                  height: 10.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.r,
                    color: AppStyle.white,
                  ),
                )
              : Icon(iconData, color: AppStyle.white, size: 20)
          : Text(
              title,
              style: AppStyle.interNormal(size: 15, color: AppStyle.white),
            ),
    );
  }
}
