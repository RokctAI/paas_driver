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


import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';

/// The plane mechanism (the approved plane proposal, frame 1c).
///
/// A wide window is divided into 1, 2, or 3 EQUAL-WIDTH PLANES by real
/// logical width — the same Material 3 breakpoints as [AppBreakpoints]:
/// phones (< 600) get one plane, unfolded folding phones (600..839) two,
/// tablet/desktop windows (>= 840) three. The user's page flow is then
/// WINDOWED onto those planes: instead of each step covering the screen
/// (the phone model), the newest steps of the flow sit side by side, the
/// deepest step in the LAST plane.
///
/// Importance is DECLARED and DYNAMIC. A page declares its claim in
/// planes ([PlanePage.span] — "I'm important, give me two", or
/// "give me a second one only if it would otherwise sit empty"); the claim of
/// the ACTIVE page (the flow's newest step) always wins at that moment,
/// and earlier pages YIELD by compressing: the page just under the active
/// step keeps whatever planes remain (up to its own claim) and re-spreads
/// onto them — a spread profile yields one plane to an arriving page and
/// compresses from three columns to two — then the next page outward,
/// until planes run out and the rest slide off. Navigating deeper
/// replaces the last plane's content; BACK pops the newest step and the
/// planes it held return to the pages beneath (back restores). A claim is
/// counted in planes and is never demoted while planes exist: asking for
/// at least as many planes as the screen has means the full screen. On a
/// one-plane (phone) screen every page renders its phone layout — the
/// mechanism disappears by construction.
///
/// Sheets and dialogs never take planes — they overlay, exactly as on
/// the phone.

/// A page's plane claim, declared in planes — never in pixels.
enum PlaneSpan {
  /// The default claim: exactly one plane. Thin pages are safe by
  /// construction — natural width, never stretched.
  one,

  /// "I'm important — give me two planes."
  two,

  /// Fill every plane the screen has (with [PlanePage.allowNeighbors]
  /// false this is a page that always presents alone).
  all,

  /// "One plane — and a SECOND one only if it would otherwise sit
  /// empty."
  ///
  /// A claim that GROWS instead of demanding. The page asks for one
  /// plane like any default page, so it never displaces the flow
  /// beneath it; then, once the earlier pages have taken what they
  /// claim, it absorbs a leftover plane rather than leaving an empty
  /// stage — up to two planes in total.
  ///
  /// The motivating case is a page with a second half it can show but
  /// does not need to (the lesson session's attendees panel, which is
  /// otherwise a swipe away inside the page): two planes shows both,
  /// one plane shows the page exactly as a phone does, and the page
  /// underneath is never pushed off to arrange it.
  ///
  /// Unlike [two] this is not a demand, so it is [claimFor] 1 — the
  /// growth is GRANTED by [PlaneHost] out of what would have been the
  /// empty stage, never taken from a neighbour.
  twoIfSpare;

  /// The claim in planes on a screen offering [count] planes. Claims are
  /// never demoted while planes exist; a claim of at least [count] means
  /// the full screen.
  ///
  /// This is the claim the page MAKES — what it takes before anyone
  /// else is served. [twoIfSpare] makes the smallest claim there is and
  /// grows afterwards; see [growthCapFor].
  int claimFor(int count) => switch (this) {
        PlaneSpan.one => 1,
        PlaneSpan.two => math.min(2, count),
        PlaneSpan.all => count,
        PlaneSpan.twoIfSpare => 1,
      };

  /// The most planes this claim will ever hold on a screen offering
  /// [count] — its claim plus whatever it may grow into. Identical to
  /// [claimFor] for every claim that does not grow.
  int growthCapFor(int count) => switch (this) {
        PlaneSpan.twoIfSpare => math.min(2, count),
        _ => claimFor(count),
      };
}

/// What any widget below a [PlaneHost] can ask about its planes:
///
/// ```dart
/// final planes = Planes.of(context); // .count, .index, .span
/// ```
///
/// [count] is how many planes the screen shows right now, [index] the
/// plane this page starts in, and [span] how many planes THIS page was
/// granted to spread its own content across. Inherited — subscribers
/// rebuild when the allocation changes (window resized, flow advanced or
/// popped); nothing polls.
class Planes extends InheritedWidget {
  /// How many planes the screen shows right now (1, 2, or 3).
  final int count;

  /// The plane this subtree starts in (0-based, start side first).
  final int index;

  /// How many planes this page was granted for its OWN content. A page
  /// spreading itself lays out [span] columns of [planeWidth] separated
  /// by [gap] — its columns then sit exactly on the plane grid.
  final int span;

  /// Width of one plane, in logical pixels.
  final double planeWidth;

  /// The seam between adjacent planes, in logical pixels.
  final double gap;

  const Planes({
    super.key,
    required this.count,
    required this.index,
    required this.span,
    required this.planeWidth,
    required this.gap,
    required super.child,
  });

  static Planes of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Planes>()!;

  /// Null when no [PlaneHost] is above [context] — the page is on an
  /// ordinary (phone) route and should use its phone layout.
  static Planes? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Planes>();

  /// True when this page reaches the END plane (edge padding etc).
  bool get isLast => index + span == count;

  @override
  bool updateShouldNotify(Planes oldWidget) =>
      count != oldWidget.count ||
      index != oldWidget.index ||
      span != oldWidget.span ||
      planeWidth != oldWidget.planeWidth ||
      gap != oldWidget.gap;
}

/// One step of the user flow, carrying its importance declaration.
class PlanePage {
  /// Stable identity of the step within the flow (also the subtree key,
  /// so a page keeps its state while the allocation re-flows around it).
  final String name;

  /// The page's claim while it is the ACTIVE step ([PlaneSpan.one] by
  /// default — only a page that declares importance gets more).
  final PlaneSpan span;

  /// May earlier pages sit beside this page while it is active? An
  /// important flow step (payment, receipt) says no: it presents on its
  /// own planes even when more would fit.
  final bool allowNeighbors;

  final WidgetBuilder builder;

  const PlanePage({
    required this.name,
    required this.builder,
    this.span = PlaneSpan.one,
    this.allowNeighbors = true,
  });
}

/// The host: decides the plane count from its width, grants the ACTIVE
/// page (the last entry of [stack]) its declared span, fills any
/// remaining planes with the nearest earlier pages when the active page
/// allows neighbors, and publishes [Planes] to every page subtree.
///
/// The host is deliberately declarative: [stack] IS the flow, root
/// first. Pushing a step means rebuilding with one more entry, back
/// means rebuilding with one less — the allocation re-flows and earlier
/// pages come back exactly as the model promises ("back restores").
/// Pages keep their state across re-flows (subtrees are keyed by
/// [PlanePage.name]).
class PlaneHost extends StatelessWidget {
  /// The user flow, root first; the last entry is the ACTIVE step.
  final List<PlanePage> stack;

  /// The seam between adjacent planes, in logical pixels.
  final double gap;

  /// The plane layout's back control — the approved [FloatingBackPill],
  /// parked at the BOTTOM-END CORNER (the approved corner ruling plus
  /// the 4c follow-up: "back be on the right" — directional, so END is
  /// the right corner in LTR and the left in RTL) whenever the flow is
  /// deeper than its root ("back was missing"). The caller supplies
  /// icon, label, and an onTap that pops its stack — the pill pops the
  /// NEWEST step (the last plane's content), never a spread earlier
  /// page. Null when the composed app already shows the back inside its
  /// own floating nav bar ([FloatingNavTabsMode.back]) — one back per
  /// screen, never two.
  final FloatingNavBack? back;

  const PlaneHost({
    super.key,
    required this.stack,
    this.gap = 14,
    this.back,
  });

  /// Width -> plane count: phones 1, unfolded folds 2, tablets 3 — the
  /// shared [AppBreakpoints] thresholds, so "wide" means the same thing
  /// here as everywhere else.
  static int planeCountFor(double width) {
    if (width >= AppBreakpoints.expanded) return 3;
    if (width >= AppBreakpoints.medium) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    assert(stack.isNotEmpty, 'PlaneHost needs at least one PlanePage');
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var count = planeCountFor(width);
        final active = stack.last;
        // A page that refuses neighbors clamps the visible planes to its
        // own claim — payment shows order | payment and nothing else,
        // even at a three-plane width. Planes stay equal: the visible
        // planes share the full width.
        if (!active.allowNeighbors) {
          // The growth cap, not the bare claim: a growing claim
          // ([PlaneSpan.twoIfSpare]) presenting alone has no neighbours
          // to yield to it, so the planes it would have grown into are
          // the ones to keep. Identical to the claim for every other
          // span.
          count = active.span.growthCapFor(count);
        }
        var activeSpan = active.span.claimFor(count);
        final planeWidth = (width - (count - 1) * gap) / count;

        // Remaining planes go to the nearest earlier pages BY THEIR OWN
        // CLAIMS (the approved yield ruling): the page just under the
        // active step compresses its spread onto what remains — a
        // three-plane profile keeps two planes when a default page lands
        // on top — then the next page outward, until planes run out;
        // pages further out slide off entirely. When the flow has no
        // earlier pages left, the leftover planes stay an EMPTY STAGE —
        // a lone default page on a wide screen does not stretch to fill.
        // A page that refuses neighbours has none: the planes its own
        // claim does not take are its to grow into, not a doorway for
        // the flow beneath. (For every non-growing claim this is what
        // the clamp above already achieved, since claim == cap there.)
        final earlier = active.allowNeighbors
            ? stack.sublist(0, stack.length - 1)
            : const <PlanePage>[];
        var remaining = count - activeSpan;
        final neighbors = <(PlanePage, int)>[];
        for (var i = earlier.length - 1; i >= 0 && remaining > 0; i--) {
          final span = math.min(earlier[i].span.claimFor(count), remaining);
          neighbors.insert(0, (earlier[i], span));
          remaining -= span;
        }
        // A GROWING claim ([PlaneSpan.twoIfSpare]) takes what is left
        // over — and only what is left over. The flow beneath has
        // already been served above, so growth can never displace a
        // page; it only turns what would have been an empty stage into
        // the second half of the active page. Capped by the claim's own
        // growth cap (two planes), so a growing page never sprawls
        // across a wide screen either.
        final growth = math.min(
          remaining,
          active.span.growthCapFor(count) - activeSpan,
        );
        if (growth > 0) {
          activeSpan += growth;
          remaining -= growth;
        }
        final emptyPlanes = remaining;

        // A page spanning n planes is n plane widths plus the (n - 1)
        // seams it absorbs; flexes carry the exact shares in milli-pixel
        // units so the Row can never overflow by rounding.
        double widthOf(int span) => span * planeWidth + (span - 1) * gap;

        final children = <Widget>[];
        var plane = 0;
        void add(PlanePage page, int span) {
          if (children.isNotEmpty) children.add(SizedBox(width: gap));
          children.add(
            Expanded(
              flex: (widthOf(span) * 1000).round(),
              child: Planes(
                count: count,
                index: plane,
                span: span,
                planeWidth: planeWidth,
                gap: gap,
                child: KeyedSubtree(
                  key: ValueKey('plane-page-${page.name}'),
                  child: Builder(builder: page.builder),
                ),
              ),
            ),
          );
          plane += span;
        }

        for (final (neighbor, span) in neighbors) {
          add(neighbor, span);
        }
        // The deepest step renders in the LAST plane(s).
        add(active, activeSpan);
        for (var i = 0; i < emptyPlanes; i++) {
          children.add(SizedBox(width: gap));
          children.add(
            Expanded(
              flex: (widthOf(1) * 1000).round(),
              child: const SizedBox.expand(),
            ),
          );
        }

        final planesRow = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
        // The screen's one back affordance, floated over the planes only
        // while there is somewhere to go back to. AT THE CORNER, not
        // centered — bottom-END per the approved 4c ruling ("back be on
        // the right"; directional, so it leads left in RTL), 16 logical
        // in from both edges, inside the SafeArea. Tapping it pops the
        // NEWEST step of the flow — the last plane's content — never a
        // spread earlier page.
        if (back == null || stack.length < 2) return planesRow;
        return Stack(
          children: [
            planesRow,
            PositionedDirectional(
              end: 16,
              bottom: 16,
              child: SafeArea(child: FloatingBackPill(back: back!)),
            ),
          ],
        );
      },
    );
  }
}
