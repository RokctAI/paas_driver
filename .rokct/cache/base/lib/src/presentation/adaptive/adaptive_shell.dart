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
