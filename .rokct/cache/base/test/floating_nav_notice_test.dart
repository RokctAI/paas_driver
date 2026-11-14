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
// FloatingNavTabsMode.notice: a short strip on top of the tab pill (the
// subscription due / grace notice). Absent by default; when given it sits
// above the pill and its action and close cross call back.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

FloatingNavTabsMode _tabs({FloatingNavNotice? notice}) {
  return FloatingNavTabsMode(
    tabs: const [
      FloatingNavTab(selectIcon: Icons.home, unSelectIcon: Icons.home_outlined, label: 'Home'),
      FloatingNavTab(selectIcon: Icons.star, unSelectIcon: Icons.star_border, label: 'Star'),
    ],
    currentIndex: 0,
    onSelect: (_) {},
    notice: notice,
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

const _strip = ValueKey('floating_nav.notice');

void main() {
  testWidgets('no notice by default', (tester) async {
    await tester.pumpWidget(_host(_tabs()));
    await tester.pumpAndSettle();
    expect(find.byKey(_strip), findsNothing);
  });

  testWidgets('notice sits above the pill and calls back', (tester) async {
    var acted = 0;
    var dismissed = 0;
    await tester.pumpWidget(_host(_tabs(
      notice: FloatingNavNotice(
        message: 'Your plan renews in 2 days',
        actionLabel: 'View plan',
        onAction: () => acted++,
        onDismiss: () => dismissed++,
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Your plan renews in 2 days'), findsOneWidget);
    final strip = tester.getRect(find.byKey(_strip));
    final tab = tester.getRect(find.byIcon(Icons.home));
    expect(strip.bottom, lessThanOrEqualTo(tab.top));
    await tester.tap(find.byKey(const ValueKey('floating_nav.notice.action')));
    await tester.tap(find.byKey(const ValueKey('floating_nav.notice.dismiss')));
    expect(acted, 1);
    expect(dismissed, 1);
  });
}
