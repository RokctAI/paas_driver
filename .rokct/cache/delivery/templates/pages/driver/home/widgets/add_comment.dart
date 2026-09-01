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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:${package}/presentation/component/text_fields/underline_bordered_text_field.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';



class AddComment extends StatelessWidget {
  final ValueChanged<String> onChange;

  const AddComment({super.key, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          TitleAndIcon(
            title: AppHelpers.getTranslation(TrKeys.addComment),
          ),
          24.verticalSpace,
          UnderlinedBorderTextField(
            label: AppHelpers.getTranslation(TrKeys.comment),
            onChanged: onChange,
          ),
          36.verticalSpace,
          CustomButton(
            title: AppHelpers.getTranslation(TrKeys.save),
            onPressed: context.router.maybePop,
          ),
          36.verticalSpace,
        ],
      ),
    );
  }
}
