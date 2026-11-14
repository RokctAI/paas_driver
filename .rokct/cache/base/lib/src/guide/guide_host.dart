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

import '../presentation/theme/app_style.dart';
import '../services/demo_session.dart';
import 'guide_anchor.dart';
import 'guide_definition.dart';
import 'guide_progress.dart';
import 'guide_store.dart';

/// The guides the running app shows. SDKs register their definitions during
/// DI; [wrap] nests one [GuideHost] per registered guide around the app
/// child. Empty by default, so an app that registers nothing is unchanged.
class GuideDefinitions {
  GuideDefinitions._();

  static final List<GuideDefinition> _all = [];

  static List<GuideDefinition> get all => List.unmodifiable(_all);

  /// Adds a guide. Re-registering the same id replaces it, so DI can run
  /// more than once without duplicating a guide.
  static void register(GuideDefinition definition) {
    _all.removeWhere((d) => d.id == definition.id);
    _all.add(definition);
  }

  /// Wraps [child] in a GuideHost for every registered guide.
  static Widget wrap(Widget child) {
    var wrapped = child;
    for (final definition in _all) {
      wrapped = GuideHost(definition: definition, child: wrapped);
    }
    return wrapped;
  }
}

/// Turns a guide on or off for this install. Off keeps progress; on resumes
/// an unfinished guide or restarts a finished one (see GuideProgress).
///
/// A no-op while [DemoSession.demoActive]: the guided-tour and render builds
/// must never write guide state.
Future<void> setGuideEnabled(
  GuideDefinition definition,
  bool on, {
  GuideStore store = const LocalStorageGuideStore(),
}) async {
  if (DemoSession.demoActive) return;
  final current = await store.read(definition.id);
  await store.write(definition.id, current.setEnabled(on, definition));
}

/// Shows the next coach-mark of [definition] over [child]. Mount it once,
/// high in the tree (the app's MaterialApp builder), so it outlives routes.
///
/// Off entirely while [DemoSession.demoActive]. The guided-tour build and the
/// render strip capture the whole framebuffer and drive taps, so a coach-mark
/// there would be burned into the store stills and would block the tour's
/// own taps. No state is read or written in that mode either.
class GuideHost extends StatefulWidget {
  final GuideDefinition definition;
  final Widget child;
  final GuideStore store;

  /// How often the host looks for the next step's anchor while a step is
  /// not showing. Anchors appear as the person navigates, so this polls.
  final Duration pollInterval;

  const GuideHost({
    super.key,
    required this.definition,
    required this.child,
    this.store = const LocalStorageGuideStore(),
    this.pollInterval = const Duration(milliseconds: 750),
  });

  @override
  State<GuideHost> createState() => _GuideHostState();
}

class _GuideHostState extends State<GuideHost> {
  GuideProgress? _progress;
  GuideStep? _showing;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    DemoSession.instance.addListener(_onDemoChanged);
    _load();
  }

  @override
  void dispose() {
    DemoSession.instance.removeListener(_onDemoChanged);
    _poll?.cancel();
    super.dispose();
  }

  void _onDemoChanged() {
    if (!mounted) return;
    setState(() {
      if (DemoSession.demoActive) {
        _poll?.cancel();
        _showing = null;
      } else {
        _load();
      }
    });
  }

  Future<void> _load() async {
    if (DemoSession.demoActive) return;
    final progress = await widget.store.read(widget.definition.id);
    if (!mounted) return;
    setState(() => _progress = progress);
    _schedulePoll();
  }

  void _schedulePoll() {
    _poll?.cancel();
    if (DemoSession.demoActive) return;
    _poll = Timer.periodic(widget.pollInterval, (_) => _tick());
  }

  void _tick() {
    final progress = _progress;
    if (!mounted || progress == null || DemoSession.demoActive) return;
    if (_showing != null) return;
    final next = progress.nextStep(
      widget.definition,
      isOnScreen: GuideAnchors.isOnScreen,
    );
    if (next != null) setState(() => _showing = next);
  }

  Future<void> _gotIt() async {
    final progress = _progress;
    final step = _showing;
    if (progress == null || step == null) return;
    final updated = progress.markComplete(step.id);
    setState(() {
      _progress = updated;
      _showing = null;
    });
    await widget.store.write(widget.definition.id, updated);
  }

  Future<void> _skipAll() async {
    final progress = _progress;
    if (progress == null) return;
    final updated = progress.dismissAll(widget.definition);
    setState(() {
      _progress = updated;
      _showing = null;
    });
    await widget.store.write(widget.definition.id, updated);
  }

  @override
  Widget build(BuildContext context) {
    if (DemoSession.demoActive) return widget.child;
    final step = _showing;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (step != null) _CoachMark(step: step, onGotIt: _gotIt, onSkipAll: _skipAll),
      ],
    );
  }
}

/// The scrim, spotlight and bubble for one step. The scrim is cut away
/// around the step's anchor, with a ring drawn round it, and the bubble has a
/// small arrow pointing at it, so the tip shows what it is about. The scrim
/// still blocks taps everywhere, the spotlight included; the bubble's buttons
/// are the only way forward.
class _CoachMark extends StatefulWidget {
  final GuideStep step;
  final VoidCallback onGotIt;
  final VoidCallback onSkipAll;

  const _CoachMark({
    required this.step,
    required this.onGotIt,
    required this.onSkipAll,
  });

  @override
  State<_CoachMark> createState() => _CoachMarkState();
}

class _CoachMarkState extends State<_CoachMark> {
  int _retries = 0;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final onGotIt = widget.onGotIt;
    final onSkipAll = widget.onSkipAll;
    final host = context.findRenderObject();
    final rect = host is RenderBox ? GuideAnchors.rectIn(step.anchor, host) : null;
    if (rect == null && _retries < 3) {
      // The anchor was not laid out yet when this built. Rebuild once the
      // frame has settled, a few times at most: if the anchor is gone the
      // scrim stays without a bubble rather than rebuilding every frame.
      _retries++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    final size = MediaQuery.sizeOf(context);
    // The shell's brand colours live in AppStyle, not in the ThemeData's
    // ColorScheme, so read them for the mode the inherited theme is in.
    final brightness = Theme.of(context).brightness;
    final ink = AppStyle.inkFor(brightness);
    final placeBelow = rect == null || rect.center.dy < size.height / 2;
    final hole = rect?.inflate(_spotPad);
    final card = AppStyle.cardFor(brightness);
    // The arrow's tip sits under (or over) the anchor's centre, kept inside
    // the bubble's rounded corners.
    final arrowX = rect == null
        ? 0.0
        : (size.width < 2 * (28 + _arrowHalf)
            ? size.width / 2
            : rect.center.dx.clamp(28 + _arrowHalf, size.width - 28 - _arrowHalf).toDouble());
    return Positioned.fill(
      child: Stack(
        children: [
          // Blocks taps; the dimming itself is painted below with a hole.
          const ModalBarrier(color: Colors.transparent, dismissible: false),
          IgnorePointer(
            child: CustomPaint(
              key: const ValueKey('guide.spotlight'),
              size: Size.infinite,
              painter: _SpotlightPainter(hole: hole, ring: AppStyle.primary),
            ),
          ),
          if (rect != null)
            Positioned(
              left: 16,
              right: 16,
              top: placeBelow ? hole!.bottom + _gap : null,
              bottom: placeBelow ? null : size.height - hole!.top + _gap,
              child: Material(
                color: card,
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: ink)),
                      const SizedBox(height: 6),
                      Text(step.body,
                          style: TextStyle(
                              color: AppStyle.secondaryInkFor(brightness))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: AppStyle.primary),
                              onPressed: onSkipAll,
                              child: const Text('Skip guide')),
                          const SizedBox(width: 8),
                          FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppStyle.primary),
                              onPressed: onGotIt, child: const Text('Got it')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Drawn after the bubble, so the bubble's shadow can't lay a dark
          // line across the arrow's base (Ray, 2026-11-08: "there is a little
          // gap in between"); its base runs into the bubble to join it.
          if (rect != null)
            Positioned(
              left: arrowX - _arrowHalf,
              width: _arrowHalf * 2,
              top: placeBelow ? hole!.bottom + _gap - _arrowHeight : null,
              bottom: placeBelow ? null : size.height - hole!.top + _gap - _arrowHeight,
              height: _arrowHeight + _arrowOverlap,
              child: IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('guide.arrow'),
                  painter: _ArrowPainter(color: card, up: placeBelow),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Space between the anchor and the edge of its spotlight.
const double _spotPad = 6;

/// Space between the spotlight and the bubble; the arrow fills it.
const double _gap = 14;
const double _arrowHalf = 10;
const double _arrowHeight = 10;

/// How far the arrow's base reaches into the bubble.
const double _arrowOverlap = 3;

/// Dims the screen except a rounded hole around the anchor, and rings the
/// hole so it reads as "this one".
class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final Color ring;
  const _SpotlightPainter({required this.hole, required this.ring});

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final h = hole;
    if (h == null) {
      canvas.drawPath(screen, Paint()..color = Colors.black54);
      return;
    }
    final spot = RRect.fromRectAndRadius(h, const Radius.circular(12));
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, Path()..addRRect(spot)),
      Paint()..color = Colors.black54,
    );
    canvas.drawRRect(
      spot,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole || old.ring != ring;
}

/// The bubble's pointer: a small triangle in the bubble's colour, tip toward
/// the anchor ([up] when the bubble sits below it).
class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool up;
  const _ArrowPainter({required this.color, required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    // The triangle is [_arrowHeight] tall; the rest of the box, on the
    // bubble's side, is a strip that lies on the bubble and joins the two.
    final w = size.width, h = size.height, a = _arrowHeight;
    final path = up
        ? (Path()
          ..moveTo(0, a)
          ..lineTo(w / 2, 0)
          ..lineTo(w, a)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close())
        : (Path()
          ..moveTo(0, h - a)
          ..lineTo(w / 2, h)
          ..lineTo(w, h - a)
          ..lineTo(w, 0)
          ..lineTo(0, 0)
          ..close());
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color || old.up != up;
}
