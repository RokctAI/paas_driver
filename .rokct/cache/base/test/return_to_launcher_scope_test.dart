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

// ReturnToLauncherScope (base_sdk 1.87.0): a page the launcher opened pops
// itself and hands back to Android on back; disabled, it is a plain page.

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _recordPlatform(WidgetTester tester) async {
  final List<String> calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      calls.add(call.method);
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}

Widget _app(bool enabled) => MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReturnToLauncherScope(
                enabled: enabled,
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('back'),
                  ),
                ),
              ),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );

void main() {
  test('only ?from=launcher asks for it', () {
    expect(ReturnToLauncherScope.requestedBy('launcher'), isTrue);
    expect(ReturnToLauncherScope.requestedBy(null), isFalse);
    expect(ReturnToLauncherScope.requestedBy('profile'), isFalse);
  });

  testWidgets('enabled: back pops the page and hands back to Android',
      (tester) async {
    final calls = await _recordPlatform(tester);
    await tester.pumpWidget(_app(true));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    expect(find.text('back'), findsNothing);
    expect(find.text('open'), findsOneWidget);
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('enabled on the only route: still hands back to Android',
      (tester) async {
    final calls = await _recordPlatform(tester);
    await tester.pumpWidget(MaterialApp(
      home: ReturnToLauncherScope(
        enabled: true,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('back'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('disabled: a plain pop, Android is not asked', (tester) async {
    final calls = await _recordPlatform(tester);
    await tester.pumpWidget(_app(false));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(calls, isNot(contains('SystemNavigator.pop')));
  });
}
