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
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/theme.dart';

class CustomTextFormField extends StatelessWidget {
  final String? hint;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool? obscure;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validation;
  final TextInputType? inputType;
  final List<TextInputFormatter>? inputFormatters;
  final String? initialText;
  final bool readOnly;
  final bool isError;
  final bool autoFocus;
  final double radius;

  const CustomTextFormField({
    super.key,
    this.suffixIcon,
    this.prefixIcon,
    this.onTap,
    this.obscure,
    this.validation,
    this.onChanged,
    this.controller,
    this.inputType,
    this.initialText,
    this.readOnly = false,
    this.isError = false,
    this.hint = "",
    this.radius = 16,
    this.autoFocus = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: autoFocus,
      onTap: onTap,
      maxLength: 200,
      onChanged: onChanged,
      autocorrect: true,
      inputFormatters: inputFormatters,
      obscureText: !(obscure ?? true),
      obscuringCharacter: '*',
      controller: controller,
      validator: validation,
      style: AppStyle.interNormal(size: 14.sp, color: AppStyle.textGrey),
      cursorWidth: 1,
      cursorColor: AppStyle.textGrey,
      keyboardType: inputType,
      initialValue: initialText,
      readOnly: readOnly,
      decoration: InputDecoration(
        counterText: "",
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 16.r),
        hintText: hint,
        hintStyle: AppStyle.interNormal(size: 14.sp, color: AppStyle.hintColor),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        fillColor: AppStyle.black,
        filled: false,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.merge(
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
          ),
          borderRadius: BorderRadius.circular(radius.r),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide.merge(
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
          ),
          borderRadius: BorderRadius.circular(radius.r),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.merge(
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
          ),
          borderRadius: BorderRadius.circular(radius.r),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide.merge(
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
          ),
          borderRadius: BorderRadius.circular(radius.r),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide.merge(
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
          ),
          borderRadius: BorderRadius.circular(radius.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.merge(
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
            const BorderSide(color: AppStyle.iconButtonBack, width: 0.9),
          ),
          borderRadius: BorderRadius.circular(radius.r),
        ),
      ),
    );
  }
}
