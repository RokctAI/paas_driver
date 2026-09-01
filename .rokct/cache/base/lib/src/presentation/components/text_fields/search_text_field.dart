// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


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
