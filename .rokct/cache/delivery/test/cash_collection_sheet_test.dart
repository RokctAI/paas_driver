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

// GATE 3 of design strip section 45 — the deliveryman's cash step
// (frame 45d; chips 844, 845, 846, canonical 390).
//
// The four things a later edit could quietly undo:
//
//   * the amount is entered on chip 390 and NEVER on an OS keyboard —
//     the whole point of flag (d), so there must be no EditableText on
//     the sheet;
//   * the delta line (846) is DERIVED and honest: short is red, exact
//     and over are green, and the server's expected total is what it
//     measures against;
//   * Confirm hands back what was actually typed, not the prefill;
//   * Record as credit exists only while the driver's capability says
//     so.

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keypad/money_keypad.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:delivery_sdk/src/driver/presentation/widgets/cash_collection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 900),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Future<CashCollectionSheet> _pump(
  WidgetTester tester, {
  num expected = 470,
  bool canConvertToCredit = false,
  void Function(double)? onConfirm,
  VoidCallback? onRecordAsCredit,
}) async {
  final sheet = CashCollectionSheet(
    orderId: '4211',
    expected: expected,
    customerName: 'Thandi M.',
    canConvertToCredit: canConvertToCredit,
    onConfirm: onConfirm ?? (_) {},
    onRecordAsCredit: onRecordAsCredit ?? () {},
  );
  // A tall, 1:1 surface: ScreenUtil scales against the design size, and
  // the default 800x600 test view pushes the pad's lower rows off it.
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(sheet));
  await tester.pumpAndSettle();
  return sheet;
}

Future<void> _key(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(Key('moneyKey$label')));
  await tester.pump();
}

String _readout(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const Key('cashAmountReadout')),
        matching: find.byType(Text),
      ),
    )
    .data!;

Color _deltaWash(WidgetTester tester) {
  final box = tester.widget<Container>(find.byKey(const Key('cashDeltaLine')));
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppStyle.isDark = true);

  group('chip 390 replaces the OS keyboard (flag (d))', () {
    testWidgets('the sheet carries the shared keypad and no text field',
        (tester) async {
      await _pump(tester);
      expect(find.byType(MoneyKeypad), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      expect(find.byKey(const Key('cashAmountReadout')), findsOneWidget);
    });

    testWidgets('the shipped cash-to-collect card survives', (tester) async {
      await _pump(tester);
      expect(find.byKey(const Key('cashToCollectCard')), findsOneWidget);
    });

    testWidgets('the read-out is seeded with the expected total, then edits',
        (tester) async {
      await _pump(tester, expected: 470);
      expect(_readout(tester), '470');
      await _key(tester, 'Backspace');
      expect(_readout(tester), '47');
      await _key(tester, '5');
      expect(_readout(tester), '475');
      await _key(tester, 'Decimal');
      await _key(tester, '5');
      expect(_readout(tester), '475.5');
    });
  });

  group('chip 846 - the derived delta line', () {
    testWidgets('exact reads green', (tester) async {
      await _pump(tester, expected: 470);
      expect(_deltaWash(tester), AppStyle.green.withValues(alpha: .12));
    });

    testWidgets('short reads red', (tester) async {
      await _pump(tester, expected: 470);
      await _key(tester, 'Backspace');
      // 47 against an expected 470.
      expect(_deltaWash(tester), AppStyle.red.withValues(alpha: .12));
    });

    testWidgets('over reads green', (tester) async {
      await _pump(tester, expected: 470);
      await _key(tester, '0');
      // 4700 against an expected 470.
      expect(_deltaWash(tester), AppStyle.green.withValues(alpha: .12));
    });
  });

  group('the shipped actions', () {
    testWidgets('Confirm hands back what was typed, not the prefill',
        (tester) async {
      double? confirmed;
      await _pump(
        tester,
        expected: 470,
        onConfirm: (amount) => confirmed = amount,
      );
      await _key(tester, 'Backspace');
      await _key(tester, '9');
      expect(_readout(tester), '479');
      await tester.tap(find.byType(CustomButton).first);
      await tester.pump();
      expect(confirmed, 479);
    });

    testWidgets('Record as credit appears only with the capability',
        (tester) async {
      await _pump(tester, canConvertToCredit: false);
      expect(find.byType(CustomButton), findsOneWidget);
      var recorded = false;
      await _pump(
        tester,
        canConvertToCredit: true,
        onRecordAsCredit: () => recorded = true,
      );
      expect(find.byType(CustomButton), findsNWidgets(2));
      await tester.tap(find.byType(CustomButton).last);
      await tester.pump();
      expect(recorded, isTrue);
    });
  });

  group('chip 845 - the Count it step', () {
    testWidgets('the chip is on the sheet, beside the read-out',
        (tester) async {
      await _pump(tester);
      expect(find.byKey(const Key('cashCountIt')), findsOneWidget);
    });

    test('it opens /calc by route path, asking for the number back', () {
      // ADR-005: navigation by PATH, so delivery_sdk never imports
      // calc_sdk. `pick=true` is what makes the calculator hand its
      // display back (section 45 flag (a)).
      expect(CashCollectionSheet.calcPickRoute, '/calc?pick=true');
    });
  });
}
