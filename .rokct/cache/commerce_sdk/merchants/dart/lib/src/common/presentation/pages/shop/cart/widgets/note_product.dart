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
