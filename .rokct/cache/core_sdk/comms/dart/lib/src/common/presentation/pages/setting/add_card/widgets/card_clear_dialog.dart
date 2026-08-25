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
