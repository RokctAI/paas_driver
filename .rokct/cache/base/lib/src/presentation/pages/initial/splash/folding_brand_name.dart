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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

/// The app's display name as a wordmark that folds a dotted suffix away.
///
/// A name with a dot in it (`acme.school`) is shown in full first, then
/// after [foldDelay] the dot and everything after it slide into the stem:
/// the suffix's box collapses toward the stem under a clip while the
/// suffix glyphs keep their trailing edge, so the text reads as sliding in
/// behind what stays - not as characters being backspaced, not as a fade,
/// not as one string replaced by another. The stem's glyphs never move
/// relative to the widget's leading edge. A name with no dot (or nothing in
/// front of its first dot) is plain [Text], exactly as before.
///
/// The fold uses the same easing and duration as the floating bottom bar's
/// [AnimatedSize] (`Curves.easeOutCubic`, [AppConstants.animationDuration])
/// so the two motions read as one house style. When the platform asks for
/// animations to be disabled the suffix is dropped in one step after the
/// same delay.
///
/// Which name folds is decided by [AppHelpers.appNameStem] on the value
/// alone (the server 'title' setting or the composed app's
/// [AppConstants.appTitle]) - nothing here knows any particular brand.
class FoldingBrandName extends StatefulWidget {
  const FoldingBrandName({
    super.key,
    required this.name,
    required this.style,
    this.textAlign,
    this.foldDelay = defaultFoldDelay,
    this.foldDuration = AppConstants.animationDuration,
    this.foldCurve = Curves.easeOutCubic,
  });

  /// The full display name; see [AppHelpers.appNameStem] for what folds.
  final String name;

  /// The wordmark style, applied to stem and suffix alike.
  final TextStyle style;

  /// Alignment of a name that does not fold (plain [Text]); a folding name
  /// is laid out as a single centered run.
  final TextAlign? textAlign;

  /// How long the full name stays on screen before the suffix folds.
  final Duration foldDelay;

  /// How long the fold itself takes.
  final Duration foldDuration;

  /// The fold's easing.
  final Curve foldCurve;

  /// Long enough to read the full name once; the same beat as the Next.js
  /// header's collapse.
  static const Duration defaultFoldDelay = Duration(milliseconds: 1500);

  /// The clipped box the suffix slides inside; its width is the fold's
  /// progress (full suffix width before, zero after).
  static const Key suffixKey = ValueKey<String>('folding_brand_name_suffix');

  @override
  State<FoldingBrandName> createState() => _FoldingBrandNameState();
}

class _FoldingBrandNameState extends State<FoldingBrandName>
    with SingleTickerProviderStateMixin {
  AnimationController? _fold;
  Animation<double>? _width;
  Timer? _delay;

  bool get _folds => AppHelpers.appNameFolds(widget.name);

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(FoldingBrandName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _disarm();
      _arm();
    }
  }

  @override
  void dispose() {
    _disarm();
    super.dispose();
  }

  void _arm() {
    if (!_folds) {
      return;
    }
    final controller = AnimationController(
      duration: widget.foldDuration,
      vsync: this,
    );
    _fold = controller;
    _width = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: widget.foldCurve),
    );
    _delay = Timer(widget.foldDelay, () {
      if (!mounted) {
        return;
      }
      final bool reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduceMotion) {
        controller.value = 1.0;
      } else {
        unawaited(controller.forward());
      }
    });
  }

  void _disarm() {
    _delay?.cancel();
    _delay = null;
    _fold?.dispose();
    _fold = null;
    _width = null;
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double>? width = _width;
    if (width == null) {
      return Text(widget.name, textAlign: widget.textAlign, style: widget.style);
    }
    final String stem = AppHelpers.appNameStem(widget.name);
    final String suffix = AppHelpers.appNameSuffix(widget.name);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(stem, style: widget.style),
        AnimatedBuilder(
          animation: width,
          builder: (context, child) {
            // The box shrinks from the trailing edge; the suffix stays
            // pinned to that edge, so as the box closes the glyphs slide
            // toward the stem and disappear behind its clip line.
            return ClipRect(
              key: FoldingBrandName.suffixKey,
              child: Align(
                alignment: Alignment.centerRight,
                widthFactor: width.value,
                child: child,
              ),
            );
          },
          child: Text(suffix, style: widget.style),
        ),
      ],
    );
  }
}
