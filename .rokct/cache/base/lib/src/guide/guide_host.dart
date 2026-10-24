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

/// The scrim and bubble for one step. The scrim blocks taps on the screen
/// behind it; the bubble's buttons are the only way forward. A spotlight cut
/// out of the scrim and tap-through are not in this version.
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
    return Positioned.fill(
      child: Stack(
        children: [
          ModalBarrier(color: Colors.black54, dismissible: false),
          if (rect != null)
            Positioned(
              left: 16,
              right: 16,
              top: placeBelow ? rect.bottom + 12 : null,
              bottom: placeBelow ? null : size.height - rect.top + 12,
              child: Material(
                color: AppStyle.cardFor(brightness),
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
        ],
      ),
    );
  }
}
