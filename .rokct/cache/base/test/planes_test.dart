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


// PlaneHost — the plane mechanism (the approved plane proposal):
//
//   * plane COUNT follows width: 1 below 600 logical, 2 at 600..839,
//     3 at 840 and up, planes always equal width;
//   * the NEWEST page's claim wins (dynamic importance): earlier pages
//     yield to a single plane or slide off, and back restores them;
//   * claims are counted in planes (one / two / all), never demoted
//     while planes exist; asking >= the screen's count = full screen;
//   * allowNeighbors=false presents the active page's planes alone;
//   * Planes.of(context) exposes .count/.index/.span to any subtree.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';

void main() {
  final captured = <String, Planes>{};

  PlanePage page(
    String name, {
    PlaneSpan span = PlaneSpan.one,
    bool allowNeighbors = true,
  }) {
    return PlanePage(
      name: name,
      span: span,
      allowNeighbors: allowNeighbors,
      builder: (context) {
        captured[name] = Planes.of(context);
        return Text(name);
      },
    );
  }

  Future<void> pumpHost(
    WidgetTester tester,
    double width,
    List<PlanePage> stack,
  ) async {
    captured.clear();
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PlaneHost(stack: stack),
      ),
    );
  }

  /// The rendered width of [name]'s plane subtree.
  double widthOf(WidgetTester tester, String name) =>
      tester.getSize(find.byKey(ValueKey('plane-page-$name'))).width;

  group('plane count follows width', () {
    testWidgets('below 600 logical: one plane (phone layout)',
        (tester) async {
      await pumpHost(tester, 500, [page('a')]);
      expect(captured['a']!.count, 1);
      expect(captured['a']!.index, 0);
      expect(captured['a']!.span, 1);
      expect(widthOf(tester, 'a'), moreOrLessEquals(500, epsilon: 0.5));
    });

    testWidgets('600..839: two equal planes', (tester) async {
      await pumpHost(tester, 700, [page('a'), page('b')]);
      expect(captured['a']!.count, 2);
      expect(captured['b']!.count, 2);
      // Equal width: each plane is (700 - 14) / 2.
      expect(widthOf(tester, 'a'), moreOrLessEquals(343, epsilon: 0.5));
      expect(widthOf(tester, 'b'), moreOrLessEquals(343, epsilon: 0.5));
    });

    testWidgets('840 and up: three equal planes', (tester) async {
      await pumpHost(tester, 900, [page('a'), page('b'), page('c')]);
      expect(captured['c']!.count, 3);
      final planeWidth = (900 - 2 * 14) / 3;
      for (final name in ['a', 'b', 'c']) {
        expect(
          widthOf(tester, name),
          moreOrLessEquals(planeWidth, epsilon: 0.5),
        );
      }
    });
  });

  group('dynamic importance — the newest claim wins', () {
    testWidgets('span=two active page takes two planes, earlier yields one',
        (tester) async {
      await pumpHost(tester, 900, [
        page('a'),
        page('b', span: PlaneSpan.two),
      ]);
      // Deepest step in the LAST planes: b starts at plane 1 and reaches
      // the end; a keeps the first plane.
      expect(captured['a']!.index, 0);
      expect(captured['a']!.span, 1);
      expect(captured['b']!.index, 1);
      expect(captured['b']!.span, 2);
      expect(captured['b']!.isLast, isTrue);
      final planeWidth = (900 - 2 * 14) / 3;
      expect(
        widthOf(tester, 'b'),
        moreOrLessEquals(2 * planeWidth + 14, epsilon: 0.5),
      );
      // b starts exactly on the second plane's grid line.
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('plane-page-b')))
            .dx,
        moreOrLessEquals(planeWidth + 14, epsilon: 0.5),
      );
    });

    testWidgets('earlier pages slide off when the claim leaves no room',
        (tester) async {
      await pumpHost(tester, 700, [
        page('a'),
        page('b'),
        page('c', span: PlaneSpan.two),
      ]);
      // Two planes, active claims both: a and b are off.
      expect(find.text('a'), findsNothing);
      expect(find.text('b'), findsNothing);
      expect(captured['c']!.span, 2);
      expect(captured['c']!.index, 0);
    });

    testWidgets('on a one-plane screen every page uses its phone layout',
        (tester) async {
      await pumpHost(tester, 500, [
        page('a'),
        page('b', span: PlaneSpan.two),
      ]);
      // Claims never demote below the screen: two on one plane is the
      // full (single-plane) screen — the phone layout.
      expect(find.text('a'), findsNothing);
      expect(captured['b']!.count, 1);
      expect(captured['b']!.span, 1);
    });
  });

  group('span=all', () {
    testWidgets('fills every plane the screen has', (tester) async {
      await pumpHost(tester, 900, [
        page('a'),
        page('b', span: PlaneSpan.all),
      ]);
      expect(find.text('a'), findsNothing);
      expect(captured['b']!.count, 3);
      expect(captured['b']!.index, 0);
      expect(captured['b']!.span, 3);
      expect(widthOf(tester, 'b'), moreOrLessEquals(900, epsilon: 0.5));
    });
  });

  group('allowNeighbors=false', () {
    testWidgets('presents the active page alone on its claimed planes',
        (tester) async {
      await pumpHost(tester, 900, [
        page('a'),
        page('b', span: PlaneSpan.two, allowNeighbors: false),
      ]);
      // The visible planes clamp to the claim: two planes, no neighbor,
      // sharing the full width equally.
      expect(find.text('a'), findsNothing);
      expect(captured['b']!.count, 2);
      expect(captured['b']!.span, 2);
      expect(widthOf(tester, 'b'), moreOrLessEquals(900, epsilon: 0.5));
    });
  });

  group('yield on navigate — the approved interaction ruling', () {
    testWidgets(
        'a spread page yields ONE plane to an arriving page and compresses',
        (tester) async {
      // The profile has spread across all three planes; the user opens a
      // default page: it takes the LAST plane, and the profile
      // compresses its spread onto the remaining two.
      await pumpHost(tester, 900, [
        page('profile', span: PlaneSpan.all),
        page('subjects'),
      ]);
      expect(captured['profile']!.index, 0);
      expect(captured['profile']!.span, 2);
      expect(captured['subjects']!.index, 2);
      expect(captured['subjects']!.span, 1);
      expect(captured['subjects']!.isLast, isTrue);
    });

    testWidgets('deeper navigation windows the flow onto the planes',
        (tester) async {
      await pumpHost(tester, 900, [
        page('profile', span: PlaneSpan.all),
        page('subjects'),
        page('detail'),
      ]);
      // Deepest in the LAST plane; the profile is down to one.
      expect(captured['profile']!.index, 0);
      expect(captured['profile']!.span, 1);
      expect(captured['subjects']!.index, 1);
      expect(captured['detail']!.index, 2);
      expect(captured['detail']!.isLast, isTrue);

      // BACK pops the newest step: the last plane restores what it
      // showed before, and the profile re-expands...
      await pumpHost(tester, 900, [
        page('profile', span: PlaneSpan.all),
        page('subjects'),
      ]);
      expect(find.text('detail'), findsNothing);
      expect(captured['profile']!.span, 2);
      expect(captured['subjects']!.index, 2);

      // ...and back again: the profile re-spreads across all three.
      await pumpHost(tester, 900, [
        page('profile', span: PlaneSpan.all),
      ]);
      expect(find.text('subjects'), findsNothing);
      expect(captured['profile']!.span, 3);
      expect(widthOf(tester, 'profile'), moreOrLessEquals(900, epsilon: 0.5));
    });
  });

  group('back pill', () {
    Future<void> pumpWithBack(
      WidgetTester tester,
      List<PlanePage> stack,
      VoidCallback onBack, {
      TextDirection textDirection = TextDirection.ltr,
    }) async {
      captured.clear();
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(900, 600),
            builder: (context, _) => MaterialApp(
              home: Directionality(
                textDirection: textDirection,
                child: PlaneHost(
                  stack: stack,
                  back: FloatingNavBack(
                    icon: Icons.arrow_back_ios_new,
                    label: 'Back',
                    onTap: onBack,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('sits at the bottom-START corner and pops on tap',
        (tester) async {
      var popped = 0;
      await pumpWithBack(
        tester,
        [page('profile', span: PlaneSpan.all), page('subjects')],
        () => popped++,
      );
      expect(find.byType(FloatingBackPill), findsOneWidget);
      // The corner, not the center: 16 logical in from the start (left
      // in LTR) and bottom edges.
      final rect = tester.getRect(find.byType(FloatingBackPill));
      expect(rect.left, moreOrLessEquals(16, epsilon: 0.5));
      expect(rect.bottom, moreOrLessEquals(600 - 16, epsilon: 0.5));
      await tester.tap(find.text('Back'));
      expect(popped, 1);
    });

    testWidgets('the corner is directional — trailing right in RTL',
        (tester) async {
      await pumpWithBack(
        tester,
        [page('profile', span: PlaneSpan.all), page('subjects')],
        () {},
        textDirection: TextDirection.rtl,
      );
      final rect = tester.getRect(find.byType(FloatingBackPill));
      expect(rect.right, moreOrLessEquals(900 - 16, epsilon: 0.5));
      expect(rect.bottom, moreOrLessEquals(600 - 16, epsilon: 0.5));
    });

    testWidgets('back pops the NEWEST page only — spread pages untouched',
        (tester) async {
      // [profile(all), subjects, detail]: the pill belongs to the FLOW,
      // so tapping it pops detail (the last plane's content); the
      // profile — spread on earlier planes — must not be sent home.
      final flow = [
        page('profile', span: PlaneSpan.all),
        page('subjects'),
        page('detail'),
      ];
      var backTaps = 0;
      await pumpWithBack(tester, flow, () => backTaps++);
      await tester.tap(find.text('Back'));
      expect(backTaps, 1);

      // The owner pops the newest entry and rebuilds — exactly what the
      // onTap contract asks for.
      await pumpWithBack(
        tester,
        flow.sublist(0, 2),
        () => backTaps++,
      );
      expect(find.text('detail'), findsNothing);
      expect(find.text('profile'), findsOneWidget);
      expect(find.text('subjects'), findsOneWidget);
      // Profile re-expands onto the freed plane; subjects now holds the
      // last plane. Nothing navigated "home".
      expect(captured['profile']!.index, 0);
      expect(captured['profile']!.span, 2);
      expect(captured['subjects']!.index, 2);
      expect(captured['subjects']!.isLast, isTrue);
      // Still deeper than root, so the corner pill is still there.
      expect(find.byType(FloatingBackPill), findsOneWidget);
    });

    testWidgets('absent at the flow root — nothing to go back to',
        (tester) async {
      await pumpWithBack(
        tester,
        [page('profile', span: PlaneSpan.all)],
        () {},
      );
      expect(find.byType(FloatingBackPill), findsNothing);
    });
  });

  group('back restores', () {
    testWidgets('popping the flow returns yielded planes', (tester) async {
      await pumpHost(tester, 900, [
        page('a'),
        page('b', span: PlaneSpan.two),
      ]);
      expect(captured['a']!.span, 1);
      expect(captured['b']!.span, 2);

      // Back: the flow pops to a alone — b gone, a active again.
      await pumpHost(tester, 900, [page('a')]);
      expect(find.text('b'), findsNothing);
      expect(captured['a']!.count, 3);
      expect(captured['a']!.index, 0);
      expect(captured['a']!.span, 1);
      // A lone default page does not stretch: one plane wide, the rest
      // stays an empty stage.
      expect(
        widthOf(tester, 'a'),
        moreOrLessEquals((900 - 2 * 14) / 3, epsilon: 0.5),
      );
    });
  });
}
