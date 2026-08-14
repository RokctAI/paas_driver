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
