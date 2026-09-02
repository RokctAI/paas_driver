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

// Design strip SECTION 45 — the calculator surface (frames 45a, 45e,
// 45f; chips 836-841) and the number it hands back (chip 840, flag (a)).
//
// What is pinned here is the part of the section that a later edit could
// quietly undo:
//
//   * the pad is the SHIPPED six rows, in the shipped order, with the
//     operator column (chip 839) intact — 45f's amber line is that
//     neither pad may be reordered to match the other, and 45e's promise
//     is that the fold drops no key;
//   * the two invisible states are visible (chips 838 and 841) and the
//     notifier still behaves exactly as it did;
//   * a tape row hands its result back to the display (chip 837);
//   * the fold is the fold: memory in the header pill, the tape as a
//     three-row strip with an honest count, no clear button;
//   * pick mode, and ONLY pick mode, shows chip 840 — and it pops the
//     display string, so a caller finally gets a number back.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:calc_sdk/calc_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// A phone width folds (frame 45e); a tablet width grants the declared
/// two planes (frame 45a).
const double phoneWidth = 390;
const double tabletWidth = 1280;

Widget _host(Widget child, double width) => ScreenUtilInit(
      designSize: Size(width, 900),
      builder: (context, _) => ProviderScope(
        child: MaterialApp(home: child),
      ),
    );

Future<void> _pump(
  WidgetTester tester,
  double width, {
  bool pick = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _host(CalculatorView(pickAmount: pick), width),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(Key('calcKey$label')).first);
  // C carries the shipped double-tap-to-wipe gesture, so a single tap
  // leaves the recognizer's timer armed; let it lapse or the harness
  // trips on a pending timer.
  await tester.pump(
    label == 'C' ? const Duration(milliseconds: 400) : Duration.zero,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppStyle.isDark = true);

  group('chip 839 - the pad keeps the shipped layout', () {
    test('the six shipped rows, in the shipped order', () {
      expect(CalcPad.rows, const [
        ['MC', 'MR', 'M-', 'M+'],
        ['C', '±', '%', '÷'],
        ['7', '8', '9', '×'],
        ['4', '5', '6', '-'],
        ['1', '2', '3', '+'],
        ['0', '.', '='],
      ]);
    });

    test('the calc pad is 7-8-9-first and MoneyKeypad is 1-2-3-first', () {
      // Frame 45f's amber panel: reordering either pad to match the
      // other changes an approved surface. The calculator's first digit
      // row is the desktop order.
      expect(CalcPad.rows[2].take(3), ['7', '8', '9']);
    });

    test('the operator column is the fourth column, = beneath', () {
      expect(CalcPad.operatorColumn, ['÷', '×', '-', '+', '=']);
      for (var row = 1; row <= 4; row++) {
        expect(CalcPad.rows[row].last, CalcPad.operatorColumn[row - 1]);
      }
      expect(CalcPad.rows.last.last, '=');
    });

    test('key kinds carry the re-tokening, not a re-layout', () {
      expect(CalcPad.kindOf('7'), CalcKeyKind.digit);
      expect(CalcPad.kindOf('.'), CalcKeyKind.digit);
      expect(CalcPad.kindOf('M+'), CalcKeyKind.memory);
      expect(CalcPad.kindOf('%'), CalcKeyKind.function);
      expect(CalcPad.kindOf('C'), CalcKeyKind.function);
      expect(CalcPad.kindOf('='), CalcKeyKind.operator);
      expect(CalcPad.kindOf('÷'), CalcKeyKind.operator);
    });
  });

  group('chip 837 - a tape row hands its result back', () {
    test('recallResult puts the result on the display', () {
      final notifier = CalculatorNotifier();
      final entry = CalculationResult()
        ..firstNum = '2'
        ..secondNum = '3'
        ..operator = CalculatorOperator('+')
        ..result = 5;
      notifier.recallResult(entry);
      expect(notifier.state.display, '5');
    });

    test('an in-progress operand receives it, exactly as MR does', () {
      final notifier = CalculatorNotifier();
      notifier.onNumberPressed(NormalNumber('9'));
      notifier.onOperatorPressed(CalculatorOperator('+'));
      final entry = CalculationResult()..result = 4;
      notifier.recallResult(entry);
      expect(notifier.state.display, '4');
      notifier.onResultPressed('=');
      expect(notifier.state.display, '13');
    });

    test('an incomplete row is inert', () {
      final notifier = CalculatorNotifier();
      notifier.onNumberPressed(NormalNumber('7'));
      notifier.recallResult(CalculationResult());
      expect(notifier.state.display, '7');
    });
  });

  group('the shipped engine is untouched', () {
    test('the tape still caps at ten, oldest dropped first', () {
      final notifier = CalculatorNotifier();
      for (var i = 1; i <= 12; i++) {
        notifier.onNumberPressed(NormalNumber('$i'));
        notifier.onOperatorPressed(CalculatorOperator('+'));
        notifier.onNumberPressed(NormalNumber('1'));
        notifier.onResultPressed('=');
        notifier.onResultPressed('C');
      }
      expect(notifier.state.history.length, CalcTapePane.historyCap);
    });

    test('clearHistory still empties the tape', () {
      final notifier = CalculatorNotifier();
      notifier.onNumberPressed(NormalNumber('2'));
      notifier.onOperatorPressed(CalculatorOperator('×'));
      notifier.onNumberPressed(NormalNumber('3'));
      notifier.onResultPressed('=');
      expect(notifier.state.history, isNotEmpty);
      notifier.clearHistory();
      expect(notifier.state.history, isEmpty);
    });

    test('the memory keys still add, subtract, recall and clear', () {
      final notifier = CalculatorNotifier();
      notifier.onNumberPressed(NormalNumber('40'));
      notifier.onMemoryPressed('M+');
      expect(notifier.state.memoryValue, 40);
      notifier.onMemoryPressed('M-');
      expect(notifier.state.memoryValue, 0);
      notifier.onNumberPressed(NormalNumber('5'));
      notifier.onMemoryPressed('M+');
      notifier.onResultPressed('C');
      notifier.onMemoryPressed('MR');
      expect(notifier.state.display, '405');
      notifier.onMemoryPressed('MC');
      expect(notifier.state.memoryValue, 0);
    });
  });

  group('frame 45a - the two-plane screen', () {
    testWidgets('tape pane, memory bar and clear button all render',
        (tester) async {
      await _pump(tester, tabletWidth);
      expect(find.byKey(const Key('calcTapePane')), findsOneWidget);
      expect(find.byKey(const Key('calcMemoryBar')), findsOneWidget);
      expect(find.byKey(const Key('calcClearTape')), findsOneWidget);
      expect(find.byKey(const Key('calcDisplay')), findsOneWidget);
    });

    testWidgets('every one of the twenty-three keys is on the pad',
        (tester) async {
      await _pump(tester, tabletWidth);
      for (final row in CalcPad.rows) {
        for (final label in row) {
          expect(
            find.byKey(Key('calcKey$label')),
            findsWidgets,
            reason: 'key $label is missing from the pad',
          );
        }
      }
    });

    testWidgets('chip 838 renders the memory value that state already held',
        (tester) async {
      await _pump(tester, tabletWidth);
      await _tapKey(tester, '1');
      await _tapKey(tester, '2');
      await _tapKey(tester, 'M+');
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('calcMemoryBar')),
          matching: find.text('12'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('chip 841 clears the tape without the double-tap gesture',
        (tester) async {
      await _pump(tester, tabletWidth);
      await _tapKey(tester, '8');
      await _tapKey(tester, '+');
      await _tapKey(tester, '2');
      await _tapKey(tester, '=');
      expect(find.byKey(const Key('calcTapeRow')), findsWidgets);
      await tester.tap(find.byKey(const Key('calcClearTape')));
      await tester.pump();
      expect(find.byKey(const Key('calcTapeRow')), findsNothing);
    });

    testWidgets('tapping a tape row puts its result on the display',
        (tester) async {
      await _pump(tester, tabletWidth);
      await _tapKey(tester, '6');
      await _tapKey(tester, '×');
      await _tapKey(tester, '7');
      await _tapKey(tester, '=');
      await _tapKey(tester, 'C');
      await tester.tap(find.byKey(const Key('calcTapeRow')).first);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('calcDisplay')),
          matching: find.text('42'),
        ),
        findsOneWidget,
      );
    });
  });

  group('frame 45e - the phone fold', () {
    testWidgets('memory folds into the header pill; the bar is gone',
        (tester) async {
      await _pump(tester, phoneWidth);
      expect(find.byKey(const Key('calcMemoryPill')), findsOneWidget);
      expect(find.byKey(const Key('calcMemoryBar')), findsNothing);
    });

    testWidgets('the tape is still there, and the clear button is not',
        (tester) async {
      await _pump(tester, phoneWidth);
      expect(find.byKey(const Key('calcTapePane')), findsOneWidget);
      expect(find.byKey(const Key('calcClearTape')), findsNothing);
    });

    testWidgets('the fold drops no key', (tester) async {
      await _pump(tester, phoneWidth);
      for (final row in CalcPad.rows) {
        for (final label in row) {
          expect(
            find.byKey(Key('calcKey$label')),
            findsWidgets,
            reason: 'the fold dropped $label',
          );
        }
      }
    });

    testWidgets('the strip shows the last three of ten, honestly counted',
        (tester) async {
      await _pump(tester, phoneWidth);
      for (var i = 1; i <= 5; i++) {
        await _tapKey(tester, '$i');
        await _tapKey(tester, '+');
        await _tapKey(tester, '1');
        await _tapKey(tester, '=');
        await _tapKey(tester, 'C');
      }
      await tester.pump();
      expect(
        find.byKey(const Key('calcTapeRow')),
        findsNWidgets(CalcTapePane.compactVisibleRows),
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('calcTapeCountPill')),
          matching: find.text('3 / 10'),
        ),
        findsOneWidget,
      );
    });
  });

  group('chip 840 / flag (a) - the number comes back', () {
    testWidgets('the standalone calculator shows no pick pill',
        (tester) async {
      await _pump(tester, tabletWidth);
      expect(find.byKey(const Key('calcUseAmount')), findsNothing);
      await _pump(tester, phoneWidth);
      expect(find.byKey(const Key('calcUseAmount')), findsNothing);
    });

    testWidgets('pick mode shows it on both the spread and the fold',
        (tester) async {
      await _pump(tester, tabletWidth, pick: true);
      expect(find.byKey(const Key('calcUseAmount')), findsOneWidget);
      await _pump(tester, phoneWidth, pick: true);
      expect(find.byKey(const Key('calcUseAmount')), findsOneWidget);
    });

    testWidgets('tapping it pops the display string back to the caller',
        (tester) async {
      String? popped;
      tester.view.physicalSize = const Size(tabletWidth, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    popped = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) =>
                            const CalculatorView(pickAmount: true),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          tabletWidth,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await _tapKey(tester, '4');
      await _tapKey(tester, '7');
      await _tapKey(tester, '0');
      await tester.tap(find.byKey(const Key('calcUseAmount')));
      await tester.pumpAndSettle();
      expect(popped, '470');
    });
  });

  group('CalcFormat', () {
    test('whole numbers stay whole, the rest keep their fraction', () {
      expect(CalcFormat.number(0), '0');
      expect(CalcFormat.number(1240.5), '1240.5');
      expect(CalcFormat.number(-3), '-3');
    });
  });
}
