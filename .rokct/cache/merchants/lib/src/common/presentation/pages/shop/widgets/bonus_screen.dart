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
import 'package:base_sdk/src/models/data/bonus_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class BonusScreen extends StatelessWidget {
  final BonusModel? bonus;

  const BonusScreen({super.key, required this.bonus});

  @override
  Widget build(BuildContext context) {
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyle.bgGrey.withOpacity(0.96),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              8.verticalSpace,
              Center(
                child: Container(
                  height: 4.h,
                  width: 48.w,
                  decoration: BoxDecoration(
                    color: AppStyle.dragElement,
                    borderRadius: BorderRadius.all(Radius.circular(40.r)),
                  ),
                ),
              ),
              14.verticalSpace,
              TitleAndIcon(
                title: AppHelpers.getTranslation(TrKeys.bonus),
                paddingHorizontalSize: 0,
              ),
              10.verticalSpace,
              Text(
                bonus != null
                    ? ((bonus?.type ?? "sum") == "sum")
                        ? "${bonus?.bonusStock?.product?.translation?.title ?? ""} ${AppHelpers.getTranslation(TrKeys.giftBuy)} ${AppHelpers.numberFormat(number: bonus?.value)}"
                        : "${bonus?.bonusStock?.product?.translation?.title ?? ""} ${AppHelpers.getTranslation(TrKeys.giftBuy)} ${bonus?.value ?? 0} ${AppHelpers.getTranslation(TrKeys.count)} "
                    : AppHelpers.getTranslation(TrKeys.bonus),
                style: AppStyle.interRegular(size: 14, color: AppStyle.black),
              ),
              30.verticalSpace,
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: CustomButton(
                  title: AppHelpers.getTranslation(TrKeys.wantIt),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
