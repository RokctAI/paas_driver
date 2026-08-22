// Copyright (c) 2026 RokctAI
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

import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';

/// Picks one of up to three layouts by the window's size class
/// (see [windowSizeOf]).
///
/// Only [compact] is required: a page opts into wider layouts one at a
/// time, and any class it doesn't provide falls back DOWNWARD
/// (expanded → medium → compact), so an unhandled wide window degrades to
/// the phone layout instead of breaking.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  /// Layout for phone-shaped windows — and the fallback for everything else.
  final WidgetBuilder compact;

  /// Optional layout for medium windows; falls back to [compact].
  final WidgetBuilder? medium;

  /// Optional layout for expanded windows; falls back to [medium], then
  /// [compact].
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    switch (windowSizeOf(context)) {
      case WindowSize.expanded:
        return (expanded ?? medium ?? compact)(context);
      case WindowSize.medium:
        return (medium ?? compact)(context);
      case WindowSize.compact:
        return compact(context);
    }
  }
}
