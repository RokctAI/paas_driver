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


import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

class BlurWrap extends StatelessWidget {
  /// True in the guided-tour build (TOUR_MODE), where the backdrop blur is
  /// skipped. The tour's emulator renders through SwiftShader, and a
  /// BackdropFilter over a route that is still animating took the whole
  /// emulator down (qemu SIGSEGV) on paas_customer's category results and
  /// search pages. Production builds are unaffected: the flag is a
  /// compile-time constant there. Mutable only so tests can flip it.
  static bool blurDisabled = AppConstants.isTour;

  final Widget child;
  final BorderRadius radius;
  final double blur;

  const BlurWrap({
    super.key,
    required this.child,
    required this.radius,
    this.blur = 13,
  });

  @override
  Widget build(BuildContext context) {
    if (blurDisabled) {
      return ClipRRect(borderRadius: radius, child: child);
    }
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
}
