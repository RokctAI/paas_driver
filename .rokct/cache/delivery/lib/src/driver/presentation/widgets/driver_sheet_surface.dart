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
import 'package:base_sdk/src/services/app_helpers.dart';

/// The opaque surface under every driver sheet, resolved from the theme the
/// sheet is shown in (dark: the dark surface; light: the light surface).
class DriverSheetSurface extends StatelessWidget {
  final Widget child;
  final double radius;

  const DriverSheetSurface({super.key, required this.child, this.radius = 16});

  /// The surface colour for [context]'s brightness.
  static Color color(BuildContext context) =>
      AppStyle.surfaceFor(Theme.of(context).brightness);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius.r),
          topRight: Radius.circular(radius.r),
        ),
      ),
      child: child,
    );
  }
}

/// The one way a delivery screen opens a bottom sheet.
///
/// Wraps AppHelpers.showCustomModalBottomSheet, whose route is transparent,
/// so every sheet gets the theme-aware [DriverSheetSurface] behind it and
/// the sheet follows the app's dark or light mode. Pass [surface] false only
/// when the [modal] already paints an opaque, theme-aware surface of its own
/// that covers the whole sheet.
class DriverSheet {
  DriverSheet._();

  static void show(
    BuildContext context, {
    required Widget modal,
    bool surface = true,
    bool isDrag = true,
    bool isDismissible = true,
    double paddingTop = 200,
    double radius = 16,
  }) {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      modal: modal,
      themedSurface: surface,
      isDrag: isDrag,
      isDismissible: isDismissible,
      paddingTop: paddingTop,
      radius: radius,
    );
  }
}
