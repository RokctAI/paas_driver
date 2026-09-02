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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MarketShimmerThree extends StatelessWidget {
  final bool isSimpleShop;
  final bool isShop;

  const MarketShimmerThree({
    super.key,
    this.isSimpleShop = false,
    this.isShop = false,
  });

  @override
  Widget build(BuildContext context) {
    return isShop
        ? Container(
            margin: EdgeInsets.only(right: 8.r),
            width: 134.w,
            height: 130.h,
            decoration: BoxDecoration(
              color: AppStyle.shimmerBase,
              borderRadius: BorderRadius.circular(10.r),
            ),
          )
        : Container(
            margin: isSimpleShop
                ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h)
                : EdgeInsets.only(right: 8.r),
            width: 268.w,
            height: 260.h,
            decoration: BoxDecoration(
              color: AppStyle.shimmerBase,
              borderRadius: BorderRadius.circular(10.r),
            ),
          );
  }
}
