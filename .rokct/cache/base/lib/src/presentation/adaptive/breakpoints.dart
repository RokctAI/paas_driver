import 'package:flutter/widgets.dart';

/// Material 3 window-size class the current window falls into.
///
/// Derived from real logical pixels (see [windowSizeOf]) — deliberately NOT
/// from flutter_screenutil's scaled units, so a phone-designed app running
/// in a desktop window classifies by the window it actually has.
enum WindowSize { compact, medium, expanded }

/// The Material 3 window-size-class breakpoints, in logical pixels.
///
/// Shared by every composed app so "wide" means the same thing everywhere:
/// below [medium] is a phone-shaped window, [medium]..[expanded] a small
/// tablet / split window, and [expanded]+ a desktop-shaped one.
abstract class AppBreakpoints {
  AppBreakpoints._();

  /// Width at which a window stops being [WindowSize.compact].
  static const double medium = 600;

  /// Width at which a window becomes [WindowSize.expanded].
  static const double expanded = 840;
}

/// Classifies the current window by its REAL logical width.
///
/// Uses [MediaQuery.sizeOf] so the caller rebuilds when the window is
/// resized, and so the answer is unaffected by any ScreenUtil scaling the
/// app applies further down the tree.
WindowSize windowSizeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= AppBreakpoints.expanded) return WindowSize.expanded;
  if (width >= AppBreakpoints.medium) return WindowSize.medium;
  return WindowSize.compact;
}

/// Readable predicates so call sites don't compare enum values by hand.
extension WindowSizeX on WindowSize {
  /// Phone-shaped window (narrower than [AppBreakpoints.medium]).
  bool get isCompact => this == WindowSize.compact;

  /// Anything wider than a phone — medium OR expanded. The common check
  /// for "should this page use its wide layout?".
  bool get isAtLeastMedium => this != WindowSize.compact;

  /// Desktop-shaped window ([AppBreakpoints.expanded] and up).
  bool get isExpanded => this == WindowSize.expanded;
}
