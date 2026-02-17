import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:driver/presentation/styles/style.dart';

class CustomTabBar extends StatelessWidget {
  final TabController tabController;
  final List<Tab> tabs;
  final bool scroll;

  const CustomTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
    this.scroll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.r),
      height: 48.h,
      decoration: BoxDecoration(
        color: Style.transparent,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Style.tabBarBorderColor),
      ),
      child: TabBar(
        isScrollable: scroll,
        controller: tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: Style.black,
        ),
        labelColor: Style.white,
        unselectedLabelColor: Style.textColor,
        unselectedLabelStyle: Style.interRegular(size: 14.sp),
        labelStyle: Style.interSemi(size: 14.sp),
        tabs: tabs,
      ),
    );
  }
}
