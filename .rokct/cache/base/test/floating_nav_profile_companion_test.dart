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


// FloatingNavTabsMode's profile picture and companion button (base_sdk
// 1.87.0), restored from paas_customer's pre-SDK floating nav: the picture
// renders after the tabs and takes its own tap, the companion renders beside
// the pill with its badge, both are absent by default, and a back pill that
// carries either is not the bare back pill.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _profileLabel = 'Profile';
const _cartLabel = 'Cart';

FloatingNavTabsMode _tabs({
  FloatingNavProfile? profile,
  FloatingNavAction? companion,
  FloatingNavPlacement? placement,
}) {
  return FloatingNavTabsMode(
    tabs: const [
      FloatingNavTab(
        selectIcon: Icons.home,
        unSelectIcon: Icons.home_outlined,
        label: 'Home',
      ),
    ],
    currentIndex: 0,
    onSelect: (_) {},
    profile: profile,
    companion: companion,
    tabletPlacement: placement,
  );
}

Widget _host(FloatingNavMode mode, {Size size = const Size(400, 800)}) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
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
    ),
  );
}

void main() {
  testWidgets('no profile and no companion by default', (tester) async {
    await tester.pumpWidget(_host(_tabs()));
    await tester.pumpAndSettle();

    expect(find.byType(UserAvatar), findsNothing);
    expect(find.byTooltip(_profileLabel), findsNothing);
    expect(find.byTooltip(_cartLabel), findsNothing);
  });

  testWidgets('profile draws the avatar and takes its own tap',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(_tabs(
      profile: FloatingNavProfile(
        user: ProfileData(firstname: 'Ada', lastname: 'Lovelace'),
        label: _profileLabel,
        onTap: () => taps++,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.text('AL'), findsOneWidget);
    await tester.tap(find.byTooltip(_profileLabel));
    expect(taps, 1);
  });

  testWidgets('signed out (null user) draws the person glyph',
      (tester) async {
    await tester.pumpWidget(_host(_tabs(
      profile: const FloatingNavProfile(user: null, label: _profileLabel),
    )));
    await tester.pumpAndSettle();

    expect(find.byKey(UserAvatar.glyphKey), findsOneWidget);
  });

  testWidgets('companion renders beside the pill with its badge',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(_tabs(
      companion: FloatingNavAction(
        icon: Icons.shopping_basket,
        label: _cartLabel,
        badgeCount: 3,
        onTap: () => taps++,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.shopping_basket), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // Beside the pill: to the right of the Home tab.
    expect(
      tester.getCenter(find.byIcon(Icons.shopping_basket)).dx,
      greaterThan(tester.getCenter(find.byIcon(Icons.home)).dx),
    );
    await tester.tap(find.byTooltip(_cartLabel));
    expect(taps, 1);
  });

  testWidgets('a zero badge count draws no badge', (tester) async {
    await tester.pumpWidget(_host(_tabs(
      companion: FloatingNavAction(
        icon: Icons.shopping_basket,
        label: _cartLabel,
        onTap: () {},
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsNothing);
  });

  test('hasEntries counts the profile', () {
    const back = FloatingNavBack(icon: Icons.arrow_back, label: 'Back');
    expect(
      FloatingNavTabsMode(
        tabs: const [],
        currentIndex: 0,
        onSelect: (_) {},
        back: back,
      ).hasEntries,
      isFalse,
    );
    expect(
      FloatingNavTabsMode(
        tabs: const [],
        currentIndex: 0,
        onSelect: (_) {},
        back: back,
        profile: const FloatingNavProfile(user: null, label: 'Profile'),
      ).hasEntries,
      isTrue,
    );
  });
}
