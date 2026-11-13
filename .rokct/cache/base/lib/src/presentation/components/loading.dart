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
import 'package:shimmer/shimmer.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// Shimmer colours for the current theme mode.
Color shimmerBaseFor(Brightness b) =>
    b == Brightness.dark ? AppStyle.shimmerBaseDark : AppStyle.shimmerBase;
Color shimmerHighlightFor(Brightness b) => b == Brightness.dark
    ? AppStyle.shimmerHighlightDark
    : AppStyle.shimmerHighlight;

/// Wraps [child] in the fleet shimmer for the current theme mode.
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    return Shimmer.fromColors(
      baseColor: shimmerBaseFor(b),
      highlightColor: shimmerHighlightFor(b),
      child: child,
    );
  }
}

/// The fleet's loading state: a shimmer placeholder, not a spinner
/// (Ray, 2026-11-13: "Remove spinners where you can and use shimmers").
/// In a small box (a button, a row) it is one rounded bar; with room it
/// shows three skeleton lines. [bgColor] is kept for existing callers.
class Loading extends StatelessWidget {
  final Color bgColor;

  const Loading({super.key, this.bgColor = AppStyle.textGrey});

  @override
  Widget build(BuildContext context) {
    final Color fill = AppStyle.cardFor(Theme.of(context).brightness);
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(h / 2),
          ),
        );
    return LayoutBuilder(builder: (context, c) {
      final double maxW = c.hasBoundedWidth ? c.maxWidth : 240;
      final double maxH = c.hasBoundedHeight ? c.maxHeight : 120;
      if (maxH < 72 || maxW < 120) {
        final double h = (maxH < 12 ? maxH : 12).clamp(4, 12).toDouble();
        final double w = (maxW * 0.6).clamp(16, 160).toDouble();
        return Center(child: AppShimmer(child: bar(w, h)));
      }
      final double w = (maxW - 32).clamp(80, 480).toDouble();
      return Center(
        child: AppShimmer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(w, 14),
              const SizedBox(height: 12),
              bar(w * 0.8, 14),
              const SizedBox(height: 12),
              bar(w * 0.55, 14),
            ],
          ),
        ),
      );
    });
  }
}
