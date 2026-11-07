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


// FloatingNavTab.marker: a small mark on a tab's icon (a status dot), so a
// page puts its signal on the nav instead of floating it over the pill.
// Drawn on its tab's icon in both indicator styles, absent by default.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

const _dot = Key('marker');

FloatingNavTabsMode _tabs({bool marked = true, FloatingNavIndicator indicator = FloatingNavIndicator.dash}) {
  return FloatingNavTabsMode(
    tabs: [
      FloatingNavTab(
        selectIcon: Icons.home,
        unSelectIcon: Icons.home_outlined,
        label: 'Home',
        marker: marked ? const SizedBox(key: _dot, width: 8, height: 8) : null,
      ),
      const FloatingNavTab(selectIcon: Icons.star, unSelectIcon: Icons.star_border, label: 'Star'),
    ],
    currentIndex: 1,
    onSelect: (_) {},
    indicator: indicator,
  );
}

Widget _host(FloatingNavMode mode) {
  return ProviderScope(
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.bottomCenter, child: FloatingBottomNav(mode: mode)),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('no marker by default', (tester) async {
    await tester.pumpWidget(_host(_tabs(marked: false)));
    await tester.pumpAndSettle();
    expect(find.byKey(_dot), findsNothing);
  });

  for (final indicator in FloatingNavIndicator.values) {
    testWidgets('marker sits on its tab icon top right ($indicator)', (tester) async {
      await tester.pumpWidget(_host(_tabs(indicator: indicator)));
      await tester.pumpAndSettle();
      expect(find.byKey(_dot), findsOneWidget);
      final icon = tester.getRect(find.byIcon(Icons.home_outlined));
      final dot = tester.getRect(find.byKey(_dot));
      // On the icon's top-right corner, not floating elsewhere on the bar.
      expect(dot.center.dx, greaterThan(icon.center.dx));
      expect(dot.center.dy, lessThan(icon.center.dy));
      expect((dot.center - icon.topRight).distance, lessThan(12));
    });
  }
}
