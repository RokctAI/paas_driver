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

import '../../../constants/app_constants.dart';
import '../../theme/app_style.dart';
import 'floating_nav_mode.dart';

/// One tab of the floating pill nav. Recovered from paas_customer
/// `lib/presentation/pages/main/widgets/bottom_navigator_item.dart` at
/// c273ab26^ (deleted during the ADR-008 refork) — behavior preserved:
/// icon + label shown ONLY on the active tab with an [indicator] marking
/// it (by default the original small dash underneath), all other tabs
/// icon-only, whole item collapses while the page scrolls (unless
/// [AppConstants.fixed] pins it).
class BottomNavigatorItem extends StatelessWidget {
  final VoidCallback selectItem;
  final int index;
  final int currentIndex;
  final bool isScrolling;
  final IconData selectIcon;
  final IconData unSelectIcon;
  final String label;

  /// The mark the active tab wears. [FloatingNavIndicator.dash] is the
  /// recovered original and the default; [FloatingNavIndicator.rectangle]
  /// fills a rounded rectangle in [AppStyle.primary] behind the active
  /// tab's icon + label instead.
  final FloatingNavIndicator indicator;

  const BottomNavigatorItem({
    super.key,
    required this.selectItem,
    required this.index,
    required this.selectIcon,
    required this.unSelectIcon,
    required this.currentIndex,
    required this.isScrolling,
    required this.label,
    this.indicator = FloatingNavIndicator.dash,
  });

  @override
  Widget build(BuildContext context) {
    // Check if fixed navigation is enabled
    final bool isFixed = AppConstants.fixed;

    // If fixed is true, ignore the isScrolling value
    final bool shouldHide = isFixed ? false : isScrolling;

    if (indicator == FloatingNavIndicator.rectangle) {
      return _rectangleTab(shouldHide);
    }

    return GestureDetector(
      onTap: selectItem,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: AppStyle.transparent,
        height: shouldHide ? 0.h : 45.h,
        width: shouldHide ? 0.w : 60.w,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // FittedBox guards the recovered layout on geometries the
                // original phone app never saw (desktop windows): contents
                // scale down instead of overflowing the 45.h pill row.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      index == currentIndex
                          ? Icon(
                              selectIcon,
                              size: shouldHide ? 0.r : 24.r,
                              color: AppStyle.white,
                            )
                          : Icon(
                              unSelectIcon,
                              size: shouldHide ? 0.r : 24.r,
                              color: AppStyle.white,
                            ),
                      if (index == currentIndex)
                        Text(
                          label,
                          style: TextStyle(
                            color: AppStyle.white,
                            fontSize: shouldHide ? 0.sp : 9.sp,
                            // The pill floats in a Stack over the page, so
                            // this label can end up with no Material
                            // ancestor — and Flutter's fallback text style
                            // paints a debug underline when that happens.
                            // It reads as a second line under the active
                            // tab, competing with the indicator rectangle
                            // below it. Stated explicitly so the fallback
                            // can never apply.
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                height: shouldHide ? 0.h : 4.h,
                width: shouldHide ? 0.w : 24.w,
                decoration: BoxDecoration(
                  color: index == currentIndex
                      ? AppStyle.primary
                      : AppStyle.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(100.r),
                    topRight: Radius.circular(100.r),
                  ),
                ),
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The [FloatingNavIndicator.rectangle] look: the active tab's icon +
  /// label sit ON a filled rounded rectangle in the host's brand primary
  /// ([AppStyle.primary] — injected per app, never hardcoded here), and
  /// there is no dash underneath. Inactive tabs stay icon-only on the
  /// bare pill, so only the active mark differs from the original.
  Widget _rectangleTab(bool shouldHide) {
    final bool active = index == currentIndex;
    return GestureDetector(
      onTap: selectItem,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: AppStyle.transparent,
        height: shouldHide ? 0.h : 45.h,
        width: shouldHide ? 0.w : 60.w,
        child: Center(
          // Same guard as the dash layout: contents scale down on
          // geometries the phone design never saw instead of overflowing.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: shouldHide ? 0.w : 10.w,
                vertical: shouldHide ? 0.h : 4.h,
              ),
              decoration: BoxDecoration(
                color: active ? AppStyle.primary : AppStyle.transparent,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    active ? selectIcon : unSelectIcon,
                    size: shouldHide ? 0.r : 24.r,
                    color: AppStyle.white,
                  ),
                  if (active)
                    Text(
                      label,
                      style: TextStyle(
                        color: AppStyle.white,
                        fontSize: shouldHide ? 0.sp : 9.sp,
                        // Same fallback guard as the dash layout: the pill
                        // can float with no Material ancestor, and the
                        // debug underline must never apply.
                        decoration: TextDecoration.none,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
