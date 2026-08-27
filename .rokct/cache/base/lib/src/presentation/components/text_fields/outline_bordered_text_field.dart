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
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class OutlinedBorderTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final Widget? suffixIcon;
  final bool? obscure;
  final TextEditingController? textController;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validation;
  final TextInputType? inputType;
  final String? initialText;
  final String? descriptionText;
  final bool readOnly;
  final bool isError;
  final bool isSuccess;
  final TextCapitalization? textCapitalization;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  const OutlinedBorderTextField({
    super.key,
    required this.label,
    this.suffixIcon,
    this.onTap,
    this.obscure,
    this.validation,
    this.onChanged,
    this.textController,
    this.inputType,
    this.initialText,
    this.descriptionText,
    this.readOnly = false,
    this.isError = false,
    this.isSuccess = false,
    this.textCapitalization,
    this.textInputAction,
    this.inputFormatters,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label!,
                style: AppStyle.interNormal(size: 9, color: AppStyle.textPrimary),
              ),
            ],
          ),
        TextFormField(
          // maxLines: null,
          inputFormatters: inputFormatters,
          onTap: onTap,
          autocorrect: true,
          onChanged: onChanged,
          obscureText: !(obscure ?? true),
          obscuringCharacter: '*',
          controller: textController,
          validator: validation,
          style: AppStyle.interNormal(size: 15.sp, color: AppStyle.textPrimary),
          cursorWidth: 1,
          cursorColor: AppStyle.primary,
          keyboardType: inputType,
          initialValue: initialText,
          readOnly: readOnly,
          textCapitalization:
              textCapitalization ?? TextCapitalization.sentences,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            suffixIconConstraints: BoxConstraints(
              maxHeight: 30.r,
              maxWidth: 30.r,
            ),
            suffixIcon: suffixIcon,
            hintText: hint ?? AppHelpers.getTranslation(TrKeys.typeHere),
            hintStyle: AppStyle.interNormal(
              size: 13,
              color: AppStyle.hintColor,
            ),
            contentPadding: REdgeInsets.symmetric(horizontal: 0, vertical: 8),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            fillColor: AppStyle.black,
            filled: false,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide.merge(
                const BorderSide(color: AppStyle.differBorderColor),
                const BorderSide(color: AppStyle.differBorderColor),
              ),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide.merge(
                const BorderSide(color: AppStyle.differBorderColor),
                const BorderSide(color: AppStyle.differBorderColor),
              ),
            ),
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
        ),
        if (descriptionText != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              4.verticalSpace,
              Text(
                descriptionText!,
                style: AppStyle.interRegular(
                  letterSpacing: -0.3,
                  size: 12,
                  color: isError
                      ? AppStyle.red
                      : isSuccess
                          ? AppStyle.primary
                          : AppStyle.textPrimary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
