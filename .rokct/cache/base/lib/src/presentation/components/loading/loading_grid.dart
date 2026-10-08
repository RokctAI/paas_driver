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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

class LoadingGrid extends StatelessWidget {
  final int itemCount;
  final int horizontalPadding;
  final int verticalPadding;
  final int itemBorderRadius;
  final int itemHeight;
  final int mainAxisSpacing;
  final int crossAxisCount;
  final int crossAxisSpacing;

  const LoadingGrid({
    super.key,
    this.itemCount = 10,
    this.horizontalPadding = 0,
    this.verticalPadding = 0,
    this.itemBorderRadius = 10,
    this.itemHeight = 134,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 6,
    this.crossAxisSpacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Read OUTSIDE the itemBuilder, so it is this widget's own element
    // that depends on the inherited theme rather than each tile's: a mode
    // flip then rebuilds the grid, and the builder's closure is handed the
    // new mode's fill. The app-wide AppStyle.isDark static this used is not
    // an inherited widget, so nothing rescheduled a placeholder grid at all
    // and it sat in the previous mode's grey (Ray, 2026-09-19: "glance
    // doesnt change test immediately untill you come back if you switched
    // theme mode" - the same defect, found here by the fleet audit).
    final Brightness brightness = Theme.of(context).brightness;

    return AnimationLimiter(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing.r,
          crossAxisSpacing: crossAxisSpacing.r,
          mainAxisExtent: itemHeight.r,
        ),
        itemCount: itemCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: REdgeInsets.symmetric(
          horizontal: horizontalPadding.r,
          vertical: verticalPadding.r,
        ),
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: AppConstants.animationDuration,
            columnCount: itemCount,
            child: ScaleAnimation(
              scale: 0.5,
              child: FadeInAnimation(
                child: Container(
                  height: itemHeight.h,
                  decoration: BoxDecoration(
                    color: AppStyle.cardFor(brightness),
                    borderRadius: BorderRadius.circular(itemBorderRadius.r),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
