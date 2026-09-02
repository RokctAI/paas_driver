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

class CommonAppBar extends StatelessWidget {
  final Widget child;
  final double height;
  final bool isSearchPage;

  const CommonAppBar({
    super.key,
    required this.child,
    this.height = 76,
    this.isSearchPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height.h +
          ((MediaQuery.paddingOf(context).top > 34)
              ? 34.h
              : MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: isSearchPage ? 10.h : 20.h,
          ),
          child: child,
        ),
      ),
    );
  }
}
