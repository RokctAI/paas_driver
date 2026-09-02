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

class CustomTabBar extends StatelessWidget {
  final bool isScrollable;
  final TabController tabController;
  final List<Tab> tabs;

  const CustomTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.r),
      height: 50.h,
      decoration: BoxDecoration(
        color: AppStyle.transparent,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppStyle.tabBarBorderColor),
      ),
      child: TabBar(
        isScrollable: isScrollable,
        controller: tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: AppStyle.black,
        ),
        labelColor: AppStyle.white,
        unselectedLabelColor: AppStyle.textPrimary,
        unselectedLabelStyle: AppStyle.interRegular(size: 14.sp),
        labelStyle: AppStyle.interSemi(size: 14.sp),
        tabs: tabs,
      ),
    );
  }
}
