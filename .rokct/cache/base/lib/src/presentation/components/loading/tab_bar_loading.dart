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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_assets.dart';

class TabBarLoading extends StatelessWidget {
  final int itemCount;

  const TabBarLoading({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.r,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: itemCount + 1,
        itemBuilder: (context, index) {
          return index == 0
              ? Padding(
                  padding: EdgeInsetsDirectional.only(start: 16.r, end: 8.r),
                  child: SvgPicture.asset(
                    AppAssets.svgMenu,
                    width: 22.r,
                    height: 22.r,
                  ),
                )
              : Container(
                  width: 84.r,
                  decoration: BoxDecoration(
                    color: AppStyle.white,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppStyle.white.withOpacity(0.07),
                        spreadRadius: 0,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: REdgeInsets.symmetric(horizontal: 18),
                  margin: REdgeInsets.only(right: 9),
                );
        },
      ),
    );
  }
}
