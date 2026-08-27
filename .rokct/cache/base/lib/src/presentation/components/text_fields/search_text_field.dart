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
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class SearchTextField extends StatelessWidget {
  final String? hintText;
  final Widget? suffixIcon;
  final TextEditingController? textEditingController;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Color bgColor;
  final bool isBorder;
  final bool isRead;
  final bool autofocus;
  final bool isSearchIcon;

  const SearchTextField({
    super.key,
    this.hintText,
    this.suffixIcon,
    this.textEditingController,
    this.onChanged,
    this.bgColor = AppStyle.white,
    this.isBorder = false,
    this.isRead = false,
    this.autofocus = false,
    this.onTap,
    this.isSearchIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: isRead,
      autocorrect: true,
      autofocus: autofocus,
      onTap: onTap,
      style: AppStyle.interRegular(size: 16, color: AppStyle.textPrimary),
      onChanged: onChanged,
      controller: textEditingController,
      cursorColor: AppStyle.textPrimary,
      cursorWidth: 1,
      decoration: InputDecoration(
        hintStyle: AppStyle.interNormal(size: 13, color: AppStyle.textPrimary),
        hintText: hintText ?? AppHelpers.getTranslation(TrKeys.searchApp),
        contentPadding: REdgeInsets.symmetric(horizontal: 15, vertical: 14),
        prefixIcon: isSearchIcon
            ? Icon(
                Remix.search_eye_line,
                size: 20.r,
                color: AppStyle.textPrimary,
              )
            : null,
        suffixIcon: suffixIcon,
        fillColor: bgColor.withOpacity(0.1),
        filled: true,
        focusedBorder: isBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppStyle.borderColor,
                  width: 1.2,
                ),
              )
            : InputBorder.none,
        border: isBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppStyle.borderColor,
                  width: 1.2,
                ),
              )
            : InputBorder.none,
        enabledBorder: isBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppStyle.borderColor,
                  width: 1.2,
                ),
              )
            : InputBorder.none,
      ),
    );
  }
}
