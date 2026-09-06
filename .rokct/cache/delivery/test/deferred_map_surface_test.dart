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

// DeferredMapSurface holds a platform-view child back until the page has
// settled, and never mounts it on a page that is on its way out.
//
// The bug this pins (paas_driver guided tour 34049256577, phone leg): the
// driver home was created and replaced within about a second, the
// GoogleMap's native view connected after the page was already leaving,
// and the plugin's own un-awaited `updateTileOverlays` call threw a
// channel-error nothing in the page could catch. So:
//
//   * nothing is mounted before the settle delay;
//   * the child mounts after the delay when the page is still current;
//   * a widget disposed inside the window never mounts the child and
//     leaves no timer behind (testWidgets itself fails a test that ends
//     with a pending timer, on top of the explicit checks here);
//   * a route REPLACED inside the window - the tour's exact shape - never
//     mounts the child, even though the old page lingers in the tree for
//     its exit transition;
//   * a route merely COVERED at settle time waits, and mounts the child
//     once it is current again.

import 'package:delivery_sdk/src/driver/presentation/widgets/deferred_map_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the GoogleMap: counts how many times it was built.
class _Probe extends StatelessWidget {
  const _Probe(this.builds);

  final List<int> builds;

  @override
  Widget build(BuildContext context) {
    builds.add(builds.length + 1);
    return const SizedBox.expand();
  }
}

Widget _page(List<int> builds, {Duration? delay}) => DeferredMapSurface(
      settleDelay: delay ?? DeferredMapSurface.defaultSettleDelay,
      child: _Probe(builds),
    );

void main() {
  const settle = DeferredMapSurface.defaultSettleDelay;

  test('the default settle delay outlasts a Material page transition', () {
    expect(settle, const Duration(milliseconds: 800));
    expect(settle > const Duration(milliseconds: 300) * 2, isTrue);
  });

  testWidgets('the child is not built before the settle delay', (
    tester,
  ) async {
    final builds = <int>[];
    await tester.pumpWidget(MaterialApp(home: _page(builds)));
    expect(find.byType(_Probe), findsNothing);
    expect(builds, isEmpty);

    // Several frames, but not the full delay.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(settle - const Duration(milliseconds: 201));
    expect(find.byType(_Probe), findsNothing);
    expect(builds, isEmpty);
  });

  testWidgets(
      'the child is built after the delay when still mounted and '
      'current', (tester) async {
    final builds = <int>[];
    await tester.pumpWidget(MaterialApp(home: _page(builds)));
    expect(find.byType(_Probe), findsNothing);

    await tester.pump(settle);
    expect(find.byType(_Probe), findsOneWidget);
    expect(builds, [1]);

    // Sticky: a later rebuild of the page keeps the child mounted.
    await tester.pumpWidget(MaterialApp(home: _page(builds)));
    expect(find.byType(_Probe), findsOneWidget);
  });

  testWidgets('a placeholder is drawn until the child mounts', (
    tester,
  ) async {
    final builds = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: DeferredMapSurface(
          placeholder: const ColoredBox(
            key: Key('placeholder'),
            color: Colors.white,
          ),
          child: _Probe(builds),
        ),
      ),
    );
    expect(find.byKey(const Key('placeholder')), findsOneWidget);
    await tester.pump(settle);
    expect(find.byKey(const Key('placeholder')), findsNothing);
    expect(find.byType(_Probe), findsOneWidget);
  });

  testWidgets(
      'disposing before the delay never builds the child and leaves '
      'no pending timer', (tester) async {
    final builds = <int>[];
    await tester.pumpWidget(MaterialApp(home: _page(builds)));
    await tester.pump(const Duration(milliseconds: 300));

    // The page goes away inside the window.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(DeferredMapSurface), findsNothing);

    // Well past where the timer would have fired.
    await tester.pump(settle * 3);
    expect(builds, isEmpty);
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
    // testWidgets also fails this test on its own if a Timer is still
    // pending here.
  });

  testWidgets('a route replaced inside the window never builds the child', (
    tester,
  ) async {
    final builds = <int>[];
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: _page(builds)),
    );
    await tester.pump(settle - const Duration(milliseconds: 100));
    expect(builds, isEmpty);

    // The tour's shape: the home route is replaced before it has settled.
    // The old page stays in the tree for its exit transition (300 ms), so
    // the settle timer lands while it is still MOUNTED but no longer
    // current - a mounted-only guard would mount the map here, and that
    // is exactly when the plugin's post-creation calls used to land.
    navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
    );
    // A frame with both routes in the tree and the old one no longer
    // current.
    await tester.pump();
    expect(find.byType(DeferredMapSurface), findsOneWidget);

    // Past the settle mark, still inside the exit transition.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(DeferredMapSurface), findsOneWidget);
    expect(builds, isEmpty,
        reason: 'the replaced page must not spawn the view');
    await tester.pumpAndSettle();
    expect(find.byType(DeferredMapSurface), findsNothing);
    expect(builds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a route covered at settle time waits, then builds the child '
      'once current again', (tester) async {
    final builds = <int>[];
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: _page(builds)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();
    await tester.pump(settle * 2);
    expect(builds, isEmpty, reason: 'covered: nothing mounts underneath');

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(builds, isEmpty, reason: 'a fresh settle window starts here');

    await tester.pump(settle);
    expect(find.byType(_Probe), findsOneWidget);
    expect(builds, [1]);
  });
}
