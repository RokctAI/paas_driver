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

// The driver's withdraw step — the button that shipped as
// `onPressed: () {}`.
//
// The things a later edit could quietly undo:
//
//   * the amount is entered on the fleet keypad and NEVER on an OS
//     keyboard, so there must be no EditableText on the sheet;
//   * a driver cannot ask for more than the balance the page is showing
//     him, and cannot ask for zero or a negative;
//   * a NEGATIVE wallet cannot request a payout at all — the commit is
//     inert and a plain line says why (going negative is deliberate and
//     normal for a driver, so it is stated, not treated as an error);
//   * the commit hands back exactly what was typed;
//   * a request already in flight cannot be fired twice.

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/components/keypad/money_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_response.dart';
import 'package:revenue_sdk/src/driver/presentation/widgets/withdraw_sheet.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 900),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Future<void> _pump(
  WidgetTester tester, {
  num available = 1250,
  bool submitting = false,
  void Function(double)? onSubmit,
}) async {
  // A tall, 1:1 surface: ScreenUtil scales against the design size, and
  // the default 800x600 test view pushes the pad's lower rows off it.
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _host(
      WithdrawSheet(
        available: available,
        submitting: submitting,
        onSubmit: onSubmit ?? (_) {},
      ),
    ),
  );
  // While submitting the commit button spins a CircularProgressIndicator,
  // which never settles — pump one frame instead.
  if (submitting) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}

/// Types [digits] on the keypad (digits and a single '.'), using the pad's
/// published key ids — the same helper shape as delivery_sdk's cash sheet
/// test.
Future<void> _type(WidgetTester tester, String digits) async {
  for (final ch in digits.split('')) {
    final id = ch == '.' ? 'moneyKeyDecimal' : 'moneyKey$ch';
    await tester.tap(find.byKey(Key(id)));
    await tester.pump();
  }
}

Future<void> _backspace(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('moneyKeyBackspace')));
  await tester.pump();
}

CustomButton _submit(WidgetTester tester) => tester.widget<CustomButton>(
      find.byKey(const Key('withdrawSubmit')),
    );

String _readout(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const Key('withdrawAmountReadout')),
        matching: find.byType(Text),
      ),
    )
    .data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WithdrawSheet', () {
    testWidgets('enters the amount on the keypad, never an OS keyboard',
        (tester) async {
      await _pump(tester);
      expect(find.byType(MoneyKeypad), findsOneWidget);
      // No text field anywhere on the sheet: the OS keyboard can never
      // appear behind the pad.
      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('starts empty and shows the available balance',
        (tester) async {
      await _pump(tester, available: 1250);
      expect(_readout(tester), '0');
      expect(find.byKey(const Key('withdrawAvailableCard')), findsOneWidget);
    });

    testWidgets('an empty entry cannot be committed', (tester) async {
      var fired = 0;
      await _pump(tester, onSubmit: (_) => fired++);
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, 0);
    });

    testWidgets('a zero entry cannot be committed', (tester) async {
      var fired = 0;
      await _pump(tester, onSubmit: (_) => fired++);
      await _type(tester, '0');
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, 0);
      expect(find.byKey(const Key('withdrawProblemLine')), findsOneWidget);
    });

    testWidgets('an amount above the balance cannot be committed',
        (tester) async {
      var fired = 0;
      await _pump(tester, available: 100, onSubmit: (_) => fired++);
      await _type(tester, '101');
      expect(_readout(tester), '101');
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, 0);
      expect(find.byKey(const Key('withdrawProblemLine')), findsOneWidget);
    });

    testWidgets('the whole balance is committable to the cent',
        (tester) async {
      final fired = <double>[];
      await _pump(tester, available: 100, onSubmit: fired.add);
      await _type(tester, '100');
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, [100.0]);
    });

    testWidgets('commits exactly what was typed', (tester) async {
      final fired = <double>[];
      await _pump(tester, available: 1250, onSubmit: fired.add);
      await _type(tester, '42.50');
      expect(_readout(tester), '42.50');
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, [42.5]);
    });

    testWidgets('a NEGATIVE wallet cannot request a payout at all',
        (tester) async {
      var fired = 0;
      await _pump(tester, available: -320.75, onSubmit: (_) => fired++);
      // The plain explanation is up before anything is typed...
      expect(find.byKey(const Key('withdrawProblemLine')), findsOneWidget);
      // ...and no entry can unlock the commit.
      await _type(tester, '10');
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, 0);
    });

    testWidgets('a zero wallet cannot request a payout either',
        (tester) async {
      var fired = 0;
      await _pump(tester, available: 0, onSubmit: (_) => fired++);
      await _type(tester, '5');
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, 0);
    });

    testWidgets('a request in flight cannot be fired twice', (tester) async {
      var fired = 0;
      await _pump(tester, submitting: true, onSubmit: (_) => fired++);
      await _type(tester, '50');
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, 0);
      expect(_submit(tester).isLoading, isTrue);
    });

    testWidgets('backspace corrects an over-balance entry', (tester) async {
      final fired = <double>[];
      await _pump(tester, available: 100, onSubmit: fired.add);
      await _type(tester, '150');
      await _backspace(tester);
      expect(_readout(tester), '15');
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pump();
      expect(fired, [15.0]);
    });
  });

  group('PayoutRequestResponse', () {
    test('parses the accepted shape', () {
      final r = PayoutRequestResponse.fromJson(const {
        'success': true,
        'request_id': 'WPR-0007',
        'amount': 42.5,
        'new_balance': 1207.5,
      });
      expect(r.success, isTrue);
      expect(r.requestId, 'WPR-0007');
      expect(r.amount, 42.5);
      // The wallet is debited AT REQUEST TIME, so this is the balance the
      // driver already has — not a projection.
      expect(r.newBalance, 1207.5);
    });

    test('anything that is not success=true is a failure', () {
      expect(PayoutRequestResponse.fromJson(const {}).success, isFalse);
      expect(
        PayoutRequestResponse.fromJson(const {'success': 'true'}).success,
        isFalse,
      );
      expect(
        PayoutRequestResponse.fromJson(const {'success': false}).success,
        isFalse,
      );
    });

    test('a non-numeric amount or balance parses as null, never as zero', () {
      final r = PayoutRequestResponse.fromJson(const {
        'success': true,
        'amount': 'lots',
        'new_balance': null,
      });
      expect(r.amount, isNull);
      expect(r.newBalance, isNull);
    });
  });
}
