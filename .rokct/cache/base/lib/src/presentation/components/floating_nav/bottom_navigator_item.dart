import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_constants.dart';
import '../../theme/app_style.dart';

/// One tab of the floating pill nav. Recovered from paas_customer
/// `lib/presentation/pages/main/widgets/bottom_navigator_item.dart` at
/// c273ab26^ (deleted during the ADR-008 refork) — behavior preserved:
/// icon + label shown ONLY on the active tab with a small pill indicator
/// underneath it, all other tabs icon-only, whole item collapses while the
/// page scrolls (unless [AppConstants.fixed] pins it).
class BottomNavigatorItem extends StatelessWidget {
  final VoidCallback selectItem;
  final int index;
  final int currentIndex;
  final bool isScrolling;
  final IconData selectIcon;
  final IconData unSelectIcon;
  final String label;

  const BottomNavigatorItem({
    super.key,
    required this.selectItem,
    required this.index,
    required this.selectIcon,
    required this.unSelectIcon,
    required this.currentIndex,
    required this.isScrolling,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Check if fixed navigation is enabled
    final bool isFixed = AppConstants.fixed;

    // If fixed is true, ignore the isScrolling value
    final bool shouldHide = isFixed ? false : isScrolling;

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
}
