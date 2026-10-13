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

// Back to the launcher (calc_sdk 1.4.0). Ray, 2026-10-12, on the calculator
// the launcher opens inside another app: back should bring him back to the
// launcher. launch_sdk opens it with `?from=launcher`; then back pops the
// calculator and hands back to Android (SystemNavigator.pop, through
// base_sdk's ReturnToLauncherScope). Opened any other way, back is a plain
// pop and Android is not asked.

import 'dart:io';

import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:calc_sdk/calc_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pumpAndBack(
  WidgetTester tester, {
  required bool returnToLauncher,
}) async {
  final List<String> platformCalls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      platformCalls.add(call.method);
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 900),
      builder: (context, _) => ProviderScope(
        child: MaterialApp(
          home: CalculatorView(returnToLauncher: returnToLauncher),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FloatingBackPill));
  await tester.pumpAndSettle();
  return platformCalls;
}

void main() {
  setUp(() => AppStyle.isDark = true);

  testWidgets('opened by the launcher, back hands back to Android',
      (tester) async {
    final calls = await _pumpAndBack(tester, returnToLauncher: true);
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('opened in-app, back does not leave the app', (tester) async {
    final calls = await _pumpAndBack(tester, returnToLauncher: false);
    expect(calls, isNot(contains('SystemNavigator.pop')));
  });

  test('the route page reads ?from=launcher', () {
    final String page = File(
      'templates/pages/calc/calculator_page.dart',
    ).readAsStringSync();
    expect(page, contains("@QueryParam('from') this.from"));
    expect(page, contains('ReturnToLauncherScope.requestedBy(from)'));
  });
}
