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
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class UnderlineDropDown extends StatelessWidget {
  final String? value;
  final String? hint;
  final String? label;
  final List<String> list;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  const UnderlineDropDown({
    super.key,
    this.value,
    required this.list,
    required this.onChanged,
    this.hint,
    this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      padding: EdgeInsets.zero,
      hint: Text(
        AppHelpers.getTranslation(hint ?? ''),
        style: AppStyle.interNormal(
          size: 14,
          color: AppStyle.textPrimary.withOpacity(0.7),
        ),
      ),
      value: value,
      validator: validator,
      items: list.map((e) {
        return DropdownMenuItem(
          value: e,
          child: Text(AppHelpers.getTranslation(e)),
        );
      }).toList(),
      onChanged: (s) => onChanged.call(s.toString()),
      elevation: 0,
      dropdownColor: AppStyle.cardDark,
      iconEnabledColor: AppStyle.textPrimary,
      borderRadius: BorderRadius.circular(8.r),
      style: AppStyle.interNormal(),
      decoration: InputDecoration(
        contentPadding: REdgeInsets.symmetric(horizontal: 2),
        labelText:
            label != null ? "${AppHelpers.getTranslation(label!)}*" : null,
        labelStyle: AppStyle.interNormal(
          size: 14,
          color: AppStyle.textPrimary.withOpacity(0.9),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide.merge(
            const BorderSide(color: AppStyle.differBorderColor),
            const BorderSide(color: AppStyle.differBorderColor),
          ),
        ),
        errorBorder: InputBorder.none,
        border: const UnderlineInputBorder(),
        focusedErrorBorder: const UnderlineInputBorder(),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide.merge(
            const BorderSide(color: AppStyle.differBorderColor),
            const BorderSide(color: AppStyle.differBorderColor),
          ),
        ),
        focusedBorder: const UnderlineInputBorder(),
      ),
    );
  }
}
