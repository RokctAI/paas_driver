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

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CustomAppBar extends StatelessWidget {
  final Widget child;
  final double height;
  final double bottomPadding;

  const CustomAppBar({
    super.key,
    required this.child,
    this.height = 110,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height.h,
      decoration: BoxDecoration(
        // Was the polarity-PINNED AppStyle.white (0xFFFFFFFF): a ground that
        // never flips. Every call site puts default-ink labels straight on
        // it - AppStyle.interSemi/interRegular with no `color:`, which
        // resolve through AppStyle.textPrimary and go WHITE in dark mode -
        // so the bar's own titles sat white-on-white and vanished.
        // CommonAppBar, the sibling in this same folder, already grounds
        // itself on the mode-resolving cardDark; this bar was the outlier.
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: REdgeInsets.only(left: 16, right: 16, bottom: bottomPadding),
          child: child,
        ),
      ),
    );
  }
}
