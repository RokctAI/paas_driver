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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/stock.dart';
import 'package:base_sdk/src/presentation/components/custom_checkbox.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

class IngredientItem extends ConsumerWidget {
  final VoidCallback onTap;
  final VoidCallback add;
  final VoidCallback remove;
  final AddonData addon;

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
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 10.r),
        decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(10.r)),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomCheckbox(
                  isActive: addon.active ?? false,
                  onTap: onTap,
                ),
                10.horizontalSpace,
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          addon.product?.translation?.title ?? "",
                          style: AppStyle.interNormal(
                            size: 16,
                            color: AppStyle.blackColor,
                          ),
                        ),
                      ),
                      4.horizontalSpace,
                      Text(
                        "+${AppHelpers.numberFormat(number: addon.product?.stock?.totalPrice ?? 0)}",
                        style: AppStyle.interNormal(
                          size: 14,
                          color: AppStyle.black,
                        ),
                      )
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
                                  ? AppStyle.borderColor
                                  : AppStyle.blackColor,
                            ),
                          ),
                          Text(
                            "${addon.quantity ?? 1}",
                            style: AppStyle.interNormal(
                              size: 16.sp,
                            ),
                          ),
                          IconButton(
                            onPressed: add,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      )
                    : const SizedBox.shrink()
              ],
            ),
            Divider(
              color: AppStyle.bgGrey.withOpacity(0.2),
            )
          ],
        ),
      ),
    );
  }
}
