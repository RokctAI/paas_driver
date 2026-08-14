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
