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
import 'package:flutter/rendering.dart';

/// Long content (a chat message, a note, a description) shown up to
/// [collapsedHeight], fading out at the bottom, with "Show more" under it;
/// opened, it shows in full with "Show less" (Ray, 2026-11-06, from the
/// Claude app: long messages, above all ones that are not the latest,
/// should not fill the screen).
///
/// Content that fits, or is barely over ([slack]), is shown as it is with no
/// button. The fade works on any background: it fades the content itself,
/// not a painted colour over it.
class ExpandableContent extends StatefulWidget {
  final Widget child;
  final double collapsedHeight;
  final bool initiallyExpanded;
  final String moreLabel;
  final String lessLabel;

  /// How far past [collapsedHeight] content may run before it is folded.
  final double slack;

  /// The button's text style; defaults to the theme's labelLarge, muted.
  final TextStyle? labelStyle;

  const ExpandableContent({
    super.key,
    required this.child,
    this.collapsedHeight = 240,
    this.initiallyExpanded = false,
    this.moreLabel = 'Show more',
    this.lessLabel = 'Show less',
    this.slack = 48,
    this.labelStyle,
  });

  @override
  State<ExpandableContent> createState() => _ExpandableContentState();
}

class _ExpandableContentState extends State<ExpandableContent> {
  late bool _open = widget.initiallyExpanded;
  double? _full;

  void _measured(Size s) {
    if (!mounted || _full == s.height) return;
    setState(() => _full = s.height);
  }

  @override
  Widget build(BuildContext context) {
    final measured = _SizeReporter(onSize: _measured, child: widget.child);
    final full = _full;
    final tall = full != null && full > widget.collapsedHeight + widget.slack;
    if (!tall) {
      // Until measured, show it folded to the same height so a long message
      // never flashes open first.
      if (full != null) return measured;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.collapsedHeight + widget.slack),
        child: UnconstrainedBox(
          constrainedAxis: Axis.horizontal,
          alignment: Alignment.topLeft,
          clipBehavior: Clip.hardEdge,
          child: measured,
        ),
      );
    }
    final style = widget.labelStyle ??
        Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65));
    final button = Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('expandable_content.toggle'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(_open ? widget.lessLabel : widget.moreLabel, style: style),
        ),
      ),
    );
    if (_open) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [measured, button]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      ShaderMask(
        key: const ValueKey('expandable_content.fade'),
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, .62, 1],
        ).createShader(r),
        child: ClipRect(
          child: SizedBox(
            height: widget.collapsedHeight,
            child: OverflowBox(alignment: Alignment.topLeft, minHeight: 0, maxHeight: double.infinity, child: measured),
          ),
        ),
      ),
      button,
    ]);
  }
}

/// Reports its child's laid-out size after each layout that changes it.
class _SizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;
  const _SizeReporter({required this.onSize, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter r) => r.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  ValueChanged<Size> onSize;
  Size? _last;
  _RenderSizeReporter(this.onSize);

  @override
  void performLayout() {
    super.performLayout();
    final s = size;
    if (s == _last) return;
    _last = s;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(s));
  }
}
