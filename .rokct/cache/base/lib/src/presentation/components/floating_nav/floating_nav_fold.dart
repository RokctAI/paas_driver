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

/// The fold above a floating nav pill, shared by every page that scrolls
/// over one.
///
/// A scrolling page that is taller than the screen always has a fold. Where
/// the fold used to be a hard edge right against the pill (the viewport
/// simply ended above it) a card, a chart or a menu row sliced through at
/// scroll rest read as "running under the nav" (tour 1114: driver route
/// and profile, manager revenue and quick flow); where the page ran under
/// the translucent pill the rows showed through it (tour 1113b). This fades
/// the content out over [fade] logical pixels so it is gone BEFORE it
/// reaches the pill: nothing slices against the pill and nothing shows
/// through it.
///
/// [foot] is how far above the bottom of [child] the pill's top edge sits:
/// 0 when the viewport already ends above the pill, the pill's height plus
/// its offset when the content runs under it. Below that line the content
/// stays fully faded. The page keeps its own bottom padding so the last
/// item can still scroll clear of the pill.
///
/// Paint only: hit testing, scrolling and semantics are unchanged.
class FloatingNavFold extends StatelessWidget {
  final Widget child;

  /// Distance from the bottom of [child] to the top of the pill.
  final double foot;

  /// Length of the fade, ending at [foot]. 0 turns the fold off: the
  /// child paints unmasked, and a host can toggle it without rebuilding
  /// the subtree under a different parent.
  final double fade;

  const FloatingNavFold({
    super.key,
    required this.child,
    this.foot = 0,
    this.fade = 48,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final double h = bounds.height;
        // fade 0 switches the fold off (nothing is masked) while keeping
        // the same widget in the tree.
        if (h <= 0 || fade <= 0) {
          return const LinearGradient(
            colors: [Colors.black, Colors.black],
          ).createShader(bounds);
        }
        final double end = ((h - foot) / h).clamp(0.0, 1.0);
        final double start = ((h - foot - fade) / h).clamp(0.0, end);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.black,
            Colors.black,
            Colors.transparent,
            Colors.transparent,
          ],
          stops: [0, start, end, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
