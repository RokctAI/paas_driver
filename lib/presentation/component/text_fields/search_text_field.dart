import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver/infrastructure/services/app_helpers.dart';
import 'package:driver/infrastructure/services/tr_keys.dart';
import 'package:driver/presentation/styles/style.dart';

class SearchTextField extends StatelessWidget {
  final String? hintText;
  final Widget? suffixIcon;
  final TextEditingController? textEditingController;
  final ValueChanged<String>? onChanged;
  final Color bgColor;
  final bool isBorder;
  final bool isRead;

  const SearchTextField({
    super.key,
    this.hintText,
    this.suffixIcon,
    this.textEditingController,
    this.onChanged,
    this.bgColor = Style.transparent,
    this.isBorder = false,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: isRead,
      autofocus: false,
      autocorrect: true,
      style: Style.interRegular(size: 16.sp, color: Style.black),
      onChanged: onChanged,
      controller: textEditingController,
      cursorColor: Style.black,
      cursorWidth: 1,
      decoration: InputDecoration(
        hintStyle: Style.interRegular(size: 16.sp, color: Style.textColor),
        hintText: hintText ?? AppHelpers.getTranslation(TrKeys.search),
        contentPadding: REdgeInsets.symmetric(horizontal: 15, vertical: 17),
        prefixIcon: const Icon(FlutterRemix.search_2_line, color: Style.black),

        suffixIcon: suffixIcon,
        fillColor: bgColor,
        filled: true,
        focusedBorder: isBorder ? const OutlineInputBorder() : InputBorder.none,
        border: isBorder ? const OutlineInputBorder() : InputBorder.none,
        enabledBorder: isBorder ? const OutlineInputBorder() : InputBorder.none,
      ),
    );
  }
}
