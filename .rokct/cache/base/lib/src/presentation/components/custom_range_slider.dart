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


import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CustomRoundRangeSliderThumbShape extends RangeSliderThumbShape {
  const CustomRoundRangeSliderThumbShape({
    this.enabledThumbRadius = 24.0,
    this.disabledThumbRadius,
    this.elevation = 2.0,
    this.pressedElevation = 12.0,
  });

  final double enabledThumbRadius;

  final double? disabledThumbRadius;

  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  final double elevation;

  final double pressedElevation;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
      isEnabled == true ? enabledThumbRadius : _disabledThumbRadius,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    assert(sliderTheme.showValueIndicator != null);
    assert(sliderTheme.overlappingShapeStrokeColor != null);
    final Canvas canvas = context.canvas;
    final Tween<double> elevationTween = Tween<double>(
      begin: elevation,
      end: pressedElevation,
    );
    var sliderPaint = Paint()
      ..color = AppStyle.primary
      ..style = PaintingStyle.fill;

    if (isOnTop ?? false) {
      final Paint strokePaint = Paint()
        ..color = sliderTheme.overlappingShapeStrokeColor!
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 36.r, height: 20.r),
          Radius.circular(10.r),
        ),
        strokePaint,
      );
    }

    final double evaluatedElevation =
        isPressed! ? elevationTween.evaluate(activationAnimation) : elevation;
    final Path shadowPath = Path()
      ..addArc(
        Rect.fromCenter(center: center, width: 36.r, height: 20.r),
        0,
        math.pi * 2,
      );

    bool paintShadows = true;
    assert(() {
      if (debugDisableShadows) {
        _debugDrawShadow(canvas, shadowPath, evaluatedElevation);
        paintShadows = false;
      }
      return true;
    }());

    if (paintShadows) {
      canvas.drawShadow(shadowPath, AppStyle.black, evaluatedElevation, true);
    }

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 36.r, height: 20.r),
          Radius.circular(10.r),
        ),
        sliderPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 30.r, height: 12.r),
          Radius.circular(10.r),
        ),
        Paint()
          ..color = AppStyle.white
          ..style = PaintingStyle.fill,
      );
  }
}

void _debugDrawShadow(Canvas canvas, Path path, double elevation) {
  if (elevation > 0.0) {
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill
        ..strokeWidth = elevation * 2.0,
    );
  }
}
