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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/title_icon.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

import 'package:base_sdk/src/application/shop/shop_provider.dart';

class ProductFilter extends ConsumerWidget {
  final String shopId;
  final String categoryId;
  final List<String> sort;

  const ProductFilter({
    super.key,
    required this.shopId,
    required this.categoryId,
    required this.sort,
  });

  @override
  Widget build(BuildContext context, ref) {
    final event = ref.read(shopProvider.notifier);
    final state = ref.watch(shopProvider);
    return Directionality(
      textDirection:
          LocalStorage.getLangLtr() ? TextDirection.ltr : TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppStyle.bgGrey,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.r),
            topRight: Radius.circular(12.r),
          ),
        ),
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            shrinkWrap: true,
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
              18.verticalSpace,
              TitleAndIcon(
                title: AppHelpers.getTranslation(TrKeys.filter),
                rightTitleColor: AppStyle.red,
                rightTitle: AppHelpers.getTranslation(TrKeys.clearAll),
                onRightTap: () {
                  event.clear();
                },
              ),
              24.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.sortBy),
                style: AppStyle.interNoSemi(size: 16.sp, color: AppStyle.textPrimary),
              ),
              18.verticalSpace,
              Wrap(
                children: sort
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          event.changeSort(sort.indexOf(e));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          margin: EdgeInsets.only(right: 8.w, bottom: 8.h),
                          padding: EdgeInsets.symmetric(
                            vertical: 10.h,
                            horizontal: 16.w,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            color: state.sortIndex == sort.indexOf(e)
                                ? AppStyle.primary
                                : AppStyle.cardDark,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 14.w,
                                    height: 14.h,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width:
                                            state.sortIndex == sort.indexOf(e)
                                                ? 4.r
                                                : 2.r,
                                        color: AppStyle.textPrimary,
                                      ),
                                      color: AppStyle.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  6.horizontalSpace,
                                ],
                              ),
                              Text(
                                AppHelpers.getTranslation(e),
                                style: AppStyle.interNormal(
                                  size: 14,
                                  color: AppStyle.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              24.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.brands),
                style: AppStyle.interNoSemi(size: 16.sp, color: AppStyle.textPrimary),
              ),
              18.verticalSpace,
              Wrap(
                children: state.brands
                        ?.map(
                          (e) => GestureDetector(
                            onTap: () {
                              event.setBrands(id: (e.id ?? "").toString());
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin: EdgeInsets.only(right: 8.w, bottom: 8.h),
                              padding: EdgeInsets.symmetric(
                                vertical: 10.h,
                                horizontal: 16.w,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.r),
                                ),
                                color: state.brandIds.contains(e.id.toString())
                                    ? AppStyle.primary
                                    : AppStyle.cardDark,
                              ),
                              child: Text(
                                e.title ?? "",
                                style: AppStyle.interNormal(
                                  size: 14,
                                  color: AppStyle.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList() ??
                    [],
              ),
              24.verticalSpace,
              CustomButton(
                title: AppHelpers.getTranslation(TrKeys.show),
                onPressed: () {
                  context.maybePop();
                  event.fetchProductsByCategory(context, shopId, categoryId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
