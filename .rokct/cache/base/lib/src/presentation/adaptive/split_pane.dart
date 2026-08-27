// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import 'package:flutter/widgets.dart';

/// The canonical wide-window layout: a flexible [primary] pane beside a
/// fixed-width [secondary] pane (detail panel, cart, filters, ...).
///
/// Lays out as a [Row], so start/end follow the ambient text direction.
/// Meant for windows that are at least medium — on compact widths use
/// [AdaptiveShell] to fall back to a single-pane layout instead.
class SplitPane extends StatelessWidget {
  const SplitPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.secondaryWidth = 420,
    this.secondaryAtStart = false,
  });

  /// The flexible pane — takes all width the [secondary] pane doesn't.
  final Widget primary;

  /// The fixed-width pane, [secondaryWidth] logical pixels wide.
  final Widget secondary;

  /// Width of [secondary], in real logical pixels (not ScreenUtil units).
  final double secondaryWidth;

  /// When true, [secondary] sits at the START of the row (visual left in
  /// LTR, right in RTL) instead of the end.
  final bool secondaryAtStart;

  @override
  Widget build(BuildContext context) {
    final side = SizedBox(width: secondaryWidth, child: secondary);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (secondaryAtStart) side,
        Expanded(child: primary),
        if (!secondaryAtStart) side,
      ],
    );
  }
}
