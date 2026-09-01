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
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class CardClearDialog extends StatelessWidget {
  final String cardName;
  final VoidCallback cancel;
  final VoidCallback clear;

  const CardClearDialog({
    super.key,
    required this.cancel,
    required this.clear,
    required this.cardName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.sizeOf(context).width - 60.w),
      decoration: BoxDecoration(
        color: AppStyle.white.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: AppStyle.white.withOpacity(0.65),
            spreadRadius: 0,
            blurRadius: 60,
            offset: const Offset(0, 20), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.clearCard1),
            style: AppStyle.interNormal(size: 16, color: AppStyle.black),
          ),
          Text(
            cardName,
            style: AppStyle.interSemi(size: 16, color: AppStyle.black),
          ),
          Text(
            AppHelpers.getTranslation(TrKeys.clearCard2),
            style: AppStyle.interNormal(size: 16, color: AppStyle.black),
          ),
          50.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomButton(
                title: AppHelpers.getTranslation(TrKeys.cancel),
                onPressed: () {
                  // TODO cancel
                  cancel();
                  Navigator.pop(context);
                },
                weight: (MediaQuery.sizeOf(context).width - 120.w) / 2,
                background: AppStyle.black,
                textColor: AppStyle.white,
              ),
              CustomButton(
                title: AppHelpers.getTranslation(TrKeys.clear),
                onPressed: () {
                  //TODO clear
                  clear();
                  Navigator.pop(context);
                },
                weight: (MediaQuery.sizeOf(context).width - 120.w) / 2,
                background: AppStyle.red,
                textColor: AppStyle.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
