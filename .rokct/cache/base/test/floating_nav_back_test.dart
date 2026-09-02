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


// FloatingNavTabsMode's leading back segment (the approved floating-nav
// back proposal — design strip section 12): the pill grows a leading
// FloatingNavBack segment when the page passes one, renders exactly as
// before when it doesn't, taps fall back to Navigator.maybePop when the
// caller supplies no onTap, and tab selection / the active indicator are
// untouched either way. Exercised in both the bottom pill and the
// tablet-mode side rail.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _backLabel = 'Back';

FloatingNavTabsMode _tabs({
  FloatingNavBack? back,
  ValueChanged<int>? onSelect,
  FloatingNavPlacement? placement,
  int current = 0,
}) {
  return FloatingNavTabsMode(
    tabs: const [
      FloatingNavTab(
        selectIcon: Icons.home,
        unSelectIcon: Icons.home_outlined,
        label: 'Home',
      ),
      FloatingNavTab(
        selectIcon: Icons.person,
        unSelectIcon: Icons.person_outline,
        label: 'Profile',
      ),
    ],
    currentIndex: current,
    onSelect: onSelect ?? (_) {},
    back: back,
    tabletPlacement: placement,
  );
}

/// The real host composition: the bar in a Stack over the page body,
/// ProviderScope because the bar watches floatingProvider, ScreenUtilInit
/// mirroring the real app root (same as base_wallet_card_test).
Widget _host(FloatingNavMode mode) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(800, 600),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FloatingBottomNav(mode: mode),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('FloatingNavTabsMode.back — bottom pill', () {
    testWidgets('renders the leading back segment when provided',
        (tester) async {
      await tester.pumpWidget(_host(_tabs(
        back: const FloatingNavBack(
          icon: Icons.arrow_back_ios_new,
          label: _backLabel,
        ),
      )));
      await tester.pumpAndSettle();

      expect(find.text(_backLabel), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      // The tabs still render alongside it: active tab labelled, other
      // tab icon-only.
      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('renders nothing extra when back is null — fully backward '
        'compatible', (tester) async {
      await tester.pumpWidget(_host(_tabs()));
      await tester.pumpAndSettle();

      expect(find.text(_backLabel), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('null onTap falls back to Navigator.maybePop',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(800, 600),
          builder: (context, _) => MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          body: Stack(
                            children: [
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FloatingBottomNav(
                                    mode: _tabs(
                                      back: const FloatingNavBack(
                                        icon: Icons.arrow_back_ios_new,
                                        label: _backLabel,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: const Text('PUSH'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();
      expect(find.text(_backLabel), findsOneWidget);

      await tester.tap(find.text(_backLabel));
      await tester.pumpAndSettle();

      // Popped back to the first page: the pushed page's bar is gone.
      expect(find.text(_backLabel), findsNothing);
      expect(find.text('PUSH'), findsOneWidget);
    });

    testWidgets('custom onTap fires instead of popping', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(_tabs(
        back: FloatingNavBack(
          icon: Icons.arrow_back_ios_new,
          label: _backLabel,
          onTap: () => tapped++,
        ),
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_backLabel));
      await tester.pumpAndSettle();

      expect(tapped, 1);
      // Nothing popped: the bar is still on screen.
      expect(find.text(_backLabel), findsOneWidget);
    });

    testWidgets('tab selection and the active indicator are unaffected',
        (tester) async {
      final selected = <int>[];
      await tester.pumpWidget(_host(_tabs(
        back: const FloatingNavBack(
          icon: Icons.arrow_back_ios_new,
          label: _backLabel,
        ),
        onSelect: selected.add,
      )));
      await tester.pumpAndSettle();

      // Active-tab rule intact: only the current tab prints its label.
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsNothing);

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(selected, [1]);

      // Tapping the back segment selects no tab.
      await tester.tap(find.text(_backLabel));
      await tester.pumpAndSettle();
      expect(selected, [1]);
    });
  });

  group('FloatingNavTabsMode.back — tablet-mode side rail', () {
    // The default test window (800x600 logical) is already tablet-mode
    // wide (>= 600), so railStart placement takes the rail branch.
    testWidgets('renders the back segment at the rail start',
        (tester) async {
      await tester.pumpWidget(_host(_tabs(
        back: const FloatingNavBack(
          icon: Icons.arrow_back_ios_new,
          label: _backLabel,
        ),
        placement: FloatingNavPlacement.railStart,
      )));
      await tester.pumpAndSettle();

      expect(find.text(_backLabel), findsOneWidget);
      final back = tester.getCenter(find.byIcon(Icons.arrow_back_ios_new));
      final tab = tester.getCenter(find.byIcon(Icons.home));
      // Vertical rail: the back segment leads, i.e. sits ABOVE the tabs.
      expect(back.dy, lessThan(tab.dy));

      // Still tappable in the rail.
      var tapped = false;
      await tester.pumpWidget(_host(_tabs(
        back: FloatingNavBack(
          icon: Icons.arrow_back_ios_new,
          label: _backLabel,
          onTap: () => tapped = true,
        ),
        placement: FloatingNavPlacement.railStart,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_backLabel));
      expect(tapped, isTrue);
    });

    testWidgets('rail renders without it when back is null', (tester) async {
      await tester.pumpWidget(_host(_tabs(
        placement: FloatingNavPlacement.railStart,
      )));
      await tester.pumpAndSettle();

      expect(find.text(_backLabel), findsNothing);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });
  });

  // The no-tab-set apps' pushed routes (driver/delivery — design strip
  // section 12): the pill housing carrying ONLY the back segment. The
  // hairline exists to split back from the tabs, so a back-only pill
  // draws none.
  group('FloatingNavTabsMode.back — back-only pill (empty tabs)', () {
    FloatingNavTabsMode backOnly({VoidCallback? onTap}) {
      return FloatingNavTabsMode(
        tabs: const [],
        currentIndex: 0,
        onSelect: (_) {},
        back: FloatingNavBack(
          icon: Icons.arrow_back_ios_new,
          label: _backLabel,
          onTap: onTap,
        ),
      );
    }

    // The hairline is the only width-1 Container the pill draws.
    Finder hairline() => find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 1,
        );

    testWidgets('renders the back segment alone — no tabs, no hairline',
        (tester) async {
      await tester.pumpWidget(_host(backOnly()));
      await tester.pumpAndSettle();

      expect(find.text(_backLabel), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(find.byType(BottomNavigatorItem), findsNothing);
      expect(hairline(), findsNothing);
    });

    testWidgets('the hairline still splits back from tabs when tabs exist',
        (tester) async {
      await tester.pumpWidget(_host(_tabs(
        back: const FloatingNavBack(
          icon: Icons.arrow_back_ios_new,
          label: _backLabel,
        ),
      )));
      await tester.pumpAndSettle();

      expect(hairline(), findsOneWidget);
    });

    testWidgets('back-only segment taps through to onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(backOnly(onTap: () => tapped++)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_backLabel));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });
  });
}
