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
import 'package:base_sdk/src/presentation/theme/theme.dart';

class TabBarItem extends StatelessWidget {
  final bool isShopTabBar;
  final String title;
  final int index;
  final int? currentIndex;
  final VoidCallback onTap;

  const TabBarItem({
    super.key,
    required this.title,
    required this.index,
    this.isShopTabBar = false,
    this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The mode comes from the inherited theme, not from the app-wide
    // AppStyle.isDark static (Ray, 2026-09-19: "glance doesnt change test
    // immediately untill you come back if you switched theme mode" - the
    // same defect, found here by the fleet audit that followed). A static
    // is not an inherited widget, so a mode flip scheduled no rebuild of
    // this widget and it kept the previous mode's colours until something
    // else happened to rebuild it.
    final Brightness brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: isShopTabBar
              ? (currentIndex == index ? AppStyle.primary : AppStyle.cardFor(brightness))
              : AppStyle.cardFor(brightness),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: AppStyle.cardFor(brightness).withOpacity(0.07),
              spreadRadius: 0,
              blurRadius: 2,
              offset: const Offset(0, 1), // changes position of shadow
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        margin: EdgeInsets.only(right: 9.w),
        child: Center(
          child: Text(
            title,
            style: AppStyle.interNormal(
              size: 13,
              color: isShopTabBar && currentIndex == index
                  ? AppStyle.black
                  : AppStyle.inkFor(brightness),
            ),
          ),
        ),
      ),
    );
  }
}
