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

// Design strip frames 49g (method chooser), 49h (bank deposit capture) and
// 49i (deposit status) as the driver sees them.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * the balance is a SENTENCE on every one of these screens — "−1240"
//     must never appear;
//   * NOTHING moves on submit: the figure on the status plane after a send
//     is the same debt it was before, with the "unchanged until approved"
//     line under it — a pending deposit is never netted in;
//   * the amount is entered on chip 390 and never on an OS keyboard;
//   * Send for approval is inert until there is a slip;
//   * the account number is masked on screen (Copy carries the whole);
//   * a rejected row carries its reason; the trail lights the right step;
//   * no deadline, due date or "before your next shift" anywhere.

import 'package:base_sdk/src/presentation/components/keypad/money_keypad.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:delivery_sdk/src/driver/application/deposit/deposit_notifier.dart';
import 'package:delivery_sdk/src/driver/application/deposit/deposit_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_deposit_repository.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/bank_deposit_sheet.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_method_sheet.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

const _destination = DepositDestination(
  accepting: true,
  accountHolderName: 'Rokct Operations',
  bankName: 'FNB',
  accountNumber: '62000004417',
  branchCode: '250655',
  accountType: 'Cheque',
);

/// Words the frames were REJECTED for once; none may come back.
const _forbidden = [
  'before your next shift',
  'due',
  'deadline',
  'still to bank',
  '−',
  '-1240',
  '-1,240',
];

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: const Size(390, 900),
        builder: (context, _) => MaterialApp(home: child),
      ),
    );

Future<void> _pump(WidgetTester tester, Widget child,
    {List<Override> overrides = const [], bool settle = true}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(child, overrides: overrides));
  // A busy commit spins forever, so a sheet pumped in flight cannot settle.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Every rendered string, joined, lower-cased.
String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n')
    .toLowerCase();

Future<void> _key(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(Key('moneyKey$label')));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppStyle.isDark = true);

  group('49g - the method chooser', () {
    testWidgets('states the wallet as a sentence and offers both routes',
        (tester) async {
      var card = 0;
      var bank = 0;
      await _pump(
        tester,
        Scaffold(
          body: DepositMethodSheet(
            balance: -1240,
            onCard: () => card++,
            onBankDeposit: () => bank++,
          ),
        ),
      );
      final text = _allText(tester);
      for (final word in _forbidden) {
        expect(text, isNot(contains(word)), reason: 'forbidden: $word');
      }
      await tester.tap(find.byKey(const Key('depositMethodCard')));
      await tester.tap(find.byKey(const Key('depositMethodBank')));
      expect(card, 1);
      expect(bank, 1);
      expect(find.byKey(const Key('depositMethodCancel')), findsOneWidget);
    });

    testWidgets('the bank row goes inert when the tenant is not accepting',
        (tester) async {
      var bank = 0;
      await _pump(
        tester,
        Scaffold(
          body: DepositMethodSheet(
            balance: -1240,
            bankDepositsAccepted: false,
            onCard: () {},
            onBankDeposit: () => bank++,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('depositMethodBank')));
      expect(bank, 0);
    });
  });

  group('49h - the capture sheet', () {
    Future<void> pumpSheet(
      WidgetTester tester, {
      void Function(double, String, String)? onSubmit,
      String? pickedPath = '/tmp/slip.jpg',
      bool submitting = false,
    }) =>
        _pump(
          tester,
          settle: !submitting,
          Scaffold(
            body: SingleChildScrollView(
              child: BankDepositSheet(
                destination: _destination,
                reference: 'TM-0831-1642',
                initialAmount: 1240,
                submitting: submitting,
                pickSlip: (ImageSource _) async => pickedPath,
                onSubmit: onSubmit ?? (_, __, ___) {},
              ),
            ),
          ),
        );

    testWidgets('chip 390, not the OS keyboard; the account masked on screen',
        (tester) async {
      await pumpSheet(tester);
      expect(find.byType(MoneyKeypad), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      final text = _allText(tester);
      expect(text, isNot(contains('62000004417')));
      expect(text, contains('4417'));
      expect(text, contains('tm-0831-1642'));
      for (final word in _forbidden) {
        expect(text, isNot(contains(word)), reason: 'forbidden: $word');
      }
    });

    testWidgets('Send for approval waits for a slip, then hands back the facts',
        (tester) async {
      (double, String, String)? sent;
      await pumpSheet(tester, onSubmit: (a, r, p) => sent = (a, r, p));

      await tester.tap(find.byKey(const Key('bankDepositSubmit')));
      await tester.pump();
      expect(sent, isNull, reason: 'no slip yet');

      await tester.tap(find.byKey(const Key('bankDepositTakePhoto')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bankDepositSlipName')), findsOneWidget);

      // Edit the prefill: 1240.00 -> backspace x3 -> 1240 -> 1240.5
      await _key(tester, 'Backspace');
      await _key(tester, 'Backspace');
      await _key(tester, 'Backspace');
      await _key(tester, 'Decimal');
      await _key(tester, '5');

      await tester.tap(find.byKey(const Key('bankDepositSubmit')));
      await tester.pump();
      expect(sent, (1240.5, 'TM-0831-1642', '/tmp/slip.jpg'));
    });

    testWidgets('the commit is inert while a send is in flight',
        (tester) async {
      var sends = 0;
      await pumpSheet(tester, submitting: true, onSubmit: (_, __, ___) => sends++);
      await tester.tap(find.byKey(const Key('bankDepositTakePhoto')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('bankDepositSubmit')));
      await tester.pump();
      expect(sends, 0);
    });
  });

  group('49i - the status plane', () {
    late DemoDriverDepositRepository repository;
    late DepositNotifier notifier;

    setUp(() {
      repository = DemoDriverDepositRepository(
        now: () => DateTime(2026, 9, 3, 16, 42),
      );
      notifier = DepositNotifier(repository, isOnline: () async => true);
    });

    List<Override> overrides() => [
          depositProvider.overrideWith((_) => notifier),
        ];

    testWidgets('the wallet as a sentence, the history with its reasons',
        (tester) async {
      await _pump(
        tester,
        DriverDepositStatusPlane(now: DateTime(2026, 9, 3, 17, 0)),
        overrides: overrides(),
      );
      final text = _allText(tester);
      expect(text, contains('you owe'));
      expect(text, contains('1,240'));
      for (final word in _forbidden) {
        expect(text, isNot(contains(word)), reason: 'forbidden: $word');
      }
      // No live request yet: no pending card, no trail, no "unchanged".
      expect(find.byKey(const Key('depositPendingCard')), findsNothing);
      expect(find.byKey(const Key('depositStatusTrail')), findsNothing);
      expect(find.byKey(const Key('depositBalanceUnchangedLine')), findsNothing);
      // Chip 982 with chip 981 under the refusal.
      expect(find.byKey(const Key('depositRow-DEMO-DEP-2')), findsOneWidget);
      expect(find.byKey(const Key('depositRow-DEMO-DEP-1')), findsOneWidget);
      expect(
        find.byKey(const Key('depositRejectionReason-DEMO-DEP-1')),
        findsOneWidget,
      );
      expect(text, contains('bank received r 300.00'));
      expect(find.byKey(const Key('depositExplainer')), findsOneWidget);
      expect(find.byKey(const Key('depositMakeDeposit')), findsOneWidget);
    });

    testWidgets('after a send NOTHING moves: same debt, request under review',
        (tester) async {
      await _pump(
        tester,
        DriverDepositStatusPlane(now: DateTime(2026, 9, 3, 17, 0)),
        overrides: overrides(),
      );
      final before = tester
          .widget<Text>(find.byKey(const Key('depositBalanceFigure')))
          .data;

      final context = tester.element(find.byKey(const Key('depositStatusPlane')));
      DepositRecord? sent;
      await notifier.submit(
        context: context,
        amount: 1240,
        slipPath: '/tmp/slip.jpg',
        reference: 'TM-0903-1642',
        onSuccess: (row) => sent = row,
      );
      await tester.pumpAndSettle();

      expect(sent, isNotNull);
      expect(sent!.status, DepositStatus.pending);
      final after = tester
          .widget<Text>(find.byKey(const Key('depositBalanceFigure')))
          .data;
      expect(after, before, reason: 'the balance must not net the pending');
      expect(find.byKey(const Key('depositBalanceUnchangedLine')), findsOneWidget);
      expect(find.byKey(const Key('depositPendingCard')), findsOneWidget);
      expect(find.byKey(const Key('depositStatusTrail')), findsOneWidget);
      final text = _allText(tester);
      expect(text, contains('under review'));
      expect(text, contains('tm-0903-1642'));
      for (final word in _forbidden) {
        expect(text, isNot(contains(word)), reason: 'forbidden: $word');
      }
    });

    testWidgets('Make a deposit opens the chooser (49g) over the plane',
        (tester) async {
      await _pump(
        tester,
        DriverDepositStatusPlane(now: DateTime(2026, 9, 3, 17, 0)),
        overrides: overrides(),
      );
      await tester.tap(find.byKey(const Key('depositMakeDeposit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('depositMethodSheet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('depositMethodBank')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bankDepositSheet')), findsOneWidget);
    });
  });
}
