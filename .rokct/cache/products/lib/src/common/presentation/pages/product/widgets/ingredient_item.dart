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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/models/data/addons_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/vibration.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

import 'package:base_sdk/src/presentation/components/custom_checkbox.dart';

class IngredientItem extends ConsumerWidget {
  final VoidCallback onTap;
  final VoidCallback add;
  final VoidCallback remove;
  final Addons addon;

  const IngredientItem({
    required this.add,
    required this.remove,
    super.key,
    required this.onTap,
    required this.addon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        onTap();
        Vibrate.feedback(FeedbackType.selection);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 10.r),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomCheckbox(isActive: addon.active ?? false, onTap: onTap),
                10.horizontalSpace,
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          addon.product?.translation?.title ?? "",
                          style: AppStyle.interNormal(
                            size: 16,
                            color: AppStyle.textPrimary,
                          ),
                        ),
                      ),
                      4.horizontalSpace,
                      Text(
                        "+${AppHelpers.numberFormat(number: addon.product?.stock?.totalPrice)}",
                        style: AppStyle.interNoSemi(
                          size: 14,
                          color: AppStyle.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                (addon.active ?? false)
                    ? Row(
                        children: [
                          IconButton(
                            onPressed: remove,
                            icon: Icon(
                              Icons.remove,
                              color: (addon.quantity ?? 1) == 1
                                  ? AppStyle.outlineButtonBorder
                                  : AppStyle.black,
                            ),
                          ),
                          Text(
                            "${addon.quantity ?? 1}",
                            style: AppStyle.interNormal(size: 16.sp),
                          ),
                          IconButton(
                            onPressed: add,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            Divider(color: AppStyle.textGrey.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
