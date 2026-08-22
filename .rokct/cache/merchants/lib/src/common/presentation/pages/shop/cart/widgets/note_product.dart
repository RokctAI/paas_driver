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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/text_fields/outline_bordered_text_field.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';

import 'package:base_sdk/src/services/tr_keys.dart';

class NoteProduct extends StatefulWidget {
  final String? comment;
  final bool isSave;
  final ValueChanged<String> onTap;

  const NoteProduct({
    super.key,
    required this.onTap,
    this.comment,
    this.isSave = true,
  });

  @override
  State<NoteProduct> createState() => _NoteProductState();
}

class _NoteProductState extends State<NoteProduct> {
  late TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController(text: widget.comment);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TitleAndIcon(
          title: AppHelpers.getTranslation(TrKeys.productNote),
          paddingHorizontalSize: 0,
        ),
        24.verticalSpace,
        OutlinedBorderTextField(
          readOnly: !widget.isSave,
          textController: controller,
          label: AppHelpers.getTranslation(TrKeys.comment).toUpperCase(),
        ),
        32.verticalSpace,
        if (widget.isSave)
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.save),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.onTap(controller.text);
                Navigator.pop(context);
              }
            },
          ),
      ],
    );
  }
}
