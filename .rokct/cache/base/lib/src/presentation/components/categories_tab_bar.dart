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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/services/app_assets.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/category_tab_bar_item.dart';

class CategoriesTabBar extends StatelessWidget {
  // Deliberately untyped (was List<CategoryData>): this shared tab bar is the
  // seam both composed verticals feed - orders_sdk's POS passes its
  // own CategoryData and products_sdk's foods tab passes SellerCategoryData
  // (ADR-005 keeps those model twins apart). Only `.translation?.title` is
  // read, so a dynamic element type settles both call sites at once
  // (commerce#3 host-consume note, H-6/H-7).
  final List<dynamic> categories;
  final int activeIndex;
  final Function(int) onChangeTab;
  final Function() onLoading;
  final RefreshController refreshController;

  const CategoriesTabBar({
    super.key,
    required this.categories,
    required this.activeIndex,
    required this.onChangeTab,
    required this.refreshController,
    required this.onLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.r,
      child: SmartRefresher(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        enablePullDown: false,
        enablePullUp: true,
        controller: refreshController,
        onLoading: onLoading,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: categories.length + 2,
          padding: REdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (context, index) {
            return index == 0
                ? Padding(
                    padding: EdgeInsetsDirectional.only(start: 8.r, end: 8.r),
                    child: SvgPicture.asset(
                      AppAssets.svgMenu,
                      width: 22.r,
                      height: 22.r,
                    ),
                  )
                : (index == 1
                    ? CategoryTabBarItem(
                        title: AppHelpers.getTranslation(TrKeys.popular),
                        isActive: activeIndex == 1,
                        onTap: () {
                          onChangeTab(1);
                        },
                      )
                    : CategoryTabBarItem(
                        title: categories[index - 2].translation?.title ?? '--',
                        isActive: activeIndex == index,
                        onTap: () {
                          onChangeTab(index);
                        },
                      ));
          },
        ),
      ),
    );
  }
}
