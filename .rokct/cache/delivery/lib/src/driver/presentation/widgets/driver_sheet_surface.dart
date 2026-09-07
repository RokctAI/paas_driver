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


// The opaque, mode-resolving surface under every driver sheet opened
// through AppHelpers.showCustomModalBottomSheet - the helper paints the
// sheet route transparent and expects the sheet to bring its own card, as
// base_sdk's EditProfileScreen does (dark: the theme's dark surface;
// light: the soft page grey). Without it the Profile settings and vehicle
// sheets rendered as bare form fields floating over the page behind them.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class DriverSheetSurface extends StatelessWidget {
  final Widget child;

  const DriverSheetSurface({super.key, required this.child});

  /// The surface colour for the current theme mode - the same pair
  /// base_sdk's edit-profile sheet resolves.
  static Color color() =>
      AppStyle.isDark ? AppStyle.surfaceDark : AppStyle.bgGrey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color(),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: child,
    );
  }
}
