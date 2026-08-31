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

// The PRODUCTIVITY gate's hub row (approved frame 7e, chip 391 — Ray
// 2026-08-29 15:41Z): SectionsItem pumped DIRECTLY from templates/ (the
// widget carries no ${package} imports, so this harness is its compile
// gate, same contract as the POS suites). Pins the row shapes the gate
// relies on: the two-line glance row (title + seeded open/due counts) and
// the untouched single-line shape every pre-7e hub row keeps.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/services/local_storage.dart';

import '../templates/pages/manager/restaurant/widgets/sections_item.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets(
      'the Tasks gate row renders title + subtitle glance and fires its tap',
      (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_host(SectionsItem(
      title: 'Tasks',
      subtitle: '3 open · 1 due today',
      icon: Remix.task_line,
      onTap: () => tapped++,
    )));

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('3 open · 1 due today'), findsOneWidget);
    expect(find.byIcon(Remix.task_line), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    expect(tapped, 1);
  });

  testWidgets('a row without a subtitle keeps the single-line shape',
      (tester) async {
    await tester.pumpWidget(_host(SectionsItem(
      title: 'Income',
      icon: Remix.line_chart_line,
      onTap: () {},
    )));

    expect(find.text('Income'), findsOneWidget);
    // No second Text under the title: only the single title Text renders.
    expect(find.byType(Text), findsOneWidget);
  });
}
