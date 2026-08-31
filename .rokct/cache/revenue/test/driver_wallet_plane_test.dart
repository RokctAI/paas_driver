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

// The driver wallet plane — design strip frame 49f.
//
// The things a later edit could quietly undo:
//
//   * the balance is a SENTENCE and the figure is unsigned; a driver in
//     debt reads "You owe R 1,240.00" and never a minus sign;
//   * a negative balance still explains itself — the cash is docked at
//     Delivered — instead of being flagged as an error;
//   * a cash debit and the fee credit that share one settlement stay TWO
//     rows, drawn on opposite sides of zero;
//   * the statement folds to six rows and unfolds in place, because no
//     "all movements" screen has been approved;
//   * a read that fails says ONE friendly line and never the cause.

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/wallet_movement.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/driver_balance_head.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/wallet_movement_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

/// Every Text in the tree, joined — the sentence assertions read against
/// this rather than against one widget, because the balance line is built
/// from a translated lead plus a formatted figure.
String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join('\n');

WalletMovement _movement({
  String type = 'Topup',
  num amount = 10,
  String? description,
  String creation = '2026-08-31 16:42:00',
}) =>
    WalletMovement.fromJson({
      'transaction_type': type,
      'amount': amount,
      if (description != null) 'description': description,
      'creation': creation,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  group('the balance head (chip 971)', () {
    testWidgets('a NEGATIVE balance is a sentence, never a minus sign',
        (tester) async {
      await tester.pumpWidget(_host(const DriverBalanceHead(balance: -1240)));
      await tester.pumpAndSettle();

      final sentence = tester
          .widget<Text>(find.byKey(const Key('driverBalanceSentence')))
          .data!;
      expect(sentence, contains('1,240'));
      expect(sentence, isNot(contains('-')));
      expect(sentence, isNot(contains('−')));
      // And it says WHY the number is below zero.
      expect(find.byKey(const Key('driverBalanceWhyNegative')), findsOneWidget);
    });

    testWidgets('a POSITIVE balance drops the debt explanation',
        (tester) async {
      await tester.pumpWidget(_host(const DriverBalanceHead(balance: 3860)));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('driverBalanceSentence')))
            .data,
        contains('3,860'),
      );
      expect(find.byKey(const Key('driverBalanceWhyNegative')), findsNothing);
    });

    testWidgets('zero is still readable — the head never hides the figure',
        (tester) async {
      await tester.pumpWidget(_host(const DriverBalanceHead(balance: 0)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('driverBalanceSentence')), findsOneWidget);
    });

    testWidgets('the month fees row appears only once it has been read',
        (tester) async {
      await tester.pumpWidget(_host(const DriverBalanceHead(balance: 100)));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('driverBalanceFeesThisMonth')),
        findsNothing,
      );

      await tester.pumpWidget(
        _host(const DriverBalanceHead(balance: 100, feesThisMonth: 3860)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('driverBalanceFeesThisMonth')),
        findsOneWidget,
      );
    });

    testWidgets('a failed refresh says one friendly line, not the cause',
        (tester) async {
      await tester.pumpWidget(
        _host(const DriverBalanceHead(balance: 12, failed: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('driverBalanceStale')), findsOneWidget);
      final text = _allText(tester).toLowerCase();
      for (final leak in const [
        'exception',
        'dioerror',
        '417',
        'bank account',
        'not configured',
      ]) {
        expect(text, isNot(contains(leak)));
      }
    });
  });

  group('the movement list (chip 972)', () {
    testWidgets('one settlement draws as TWO rows on opposite sides of zero',
        (tester) async {
      await tester.pumpWidget(
        _host(
          WalletMovementList(
            now: DateTime(2026, 8, 31, 18),
            movements: [
              // What settle_order really writes for one cash delivery.
              _movement(
                type: 'COD Collection',
                amount: -470,
                description: 'Cash collected from customer of Order ORD-0009',
              ),
              _movement(
                type: 'Topup',
                amount: 38.5,
                description: 'Delivery fee for Order ORD-0009',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = _allText(tester);
      expect(text, contains('Cash collected from customer of Order ORD-0009'));
      expect(text, contains('Delivery fee for Order ORD-0009'));
      // Direction is drawn, and drawn opposite ways.
      expect(text, contains('−'));
      expect(text, contains('+'));
    });

    testWidgets('an UNSIGNED payout row still draws as money out',
        (tester) async {
      await tester.pumpWidget(
        _host(
          WalletMovementList(
            now: DateTime(2026, 8, 31, 18),
            movements: [
              _movement(
                type: 'Payout',
                amount: 1500,
                creation: '2026-08-28 11:40:00',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = _allText(tester);
      expect(text, contains('−'));
      expect(text, isNot(contains('+')));
      // ...and it dates itself the older way.
      expect(text, contains('28 Aug 11:40'));
    });

    testWidgets('the list folds to six rows and unfolds in place',
        (tester) async {
      var unfolded = false;
      final movements = List.generate(
        9,
        (i) => _movement(amount: i + 1, description: 'Row $i'),
      );

      await tester.pumpWidget(
        _host(
          WalletMovementList(
            movements: movements,
            now: DateTime(2026, 8, 31, 18),
            onShowAll: () => unfolded = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_allText(tester), contains('Row 5'));
      expect(_allText(tester), isNot(contains('Row 6')));
      expect(find.byKey(const Key('walletShowAllMovements')), findsOneWidget);

      await tester.tap(find.byKey(const Key('walletShowAllMovements')));
      await tester.pump();
      expect(unfolded, isTrue);

      // The unfold is the SAME screen with more rows — nothing is pushed.
      await tester.pumpWidget(
        _host(
          WalletMovementList(
            movements: movements,
            showAll: true,
            now: DateTime(2026, 8, 31, 18),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_allText(tester), contains('Row 8'));
      expect(find.byKey(const Key('walletShowAllMovements')), findsNothing);
    });

    testWidgets('six rows or fewer offer no unfold at all', (tester) async {
      await tester.pumpWidget(
        _host(
          WalletMovementList(
            now: DateTime(2026, 8, 31, 18),
            movements: List.generate(
              6,
              (i) => _movement(description: 'Row $i'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('walletShowAllMovements')), findsNothing);
    });

    testWidgets('an empty statement is stated, not left blank',
        (tester) async {
      await tester.pumpWidget(_host(const WalletMovementList(movements: [])));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('walletMovementsEmpty')), findsOneWidget);
    });

    testWidgets('a failed statement says one friendly line, not the cause',
        (tester) async {
      await tester.pumpWidget(
        _host(const WalletMovementList(movements: [], failed: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('walletMovementsFailed')), findsOneWidget);
      final text = _allText(tester).toLowerCase();
      for (final leak in const ['exception', '417', 'dioerror', 'null']) {
        expect(text, isNot(contains(leak)));
      }
    });

    testWidgets('a row with no server sentence falls back to its type, '
        'and never invents one', (tester) async {
      await tester.pumpWidget(
        _host(
          WalletMovementList(
            now: DateTime(2026, 8, 31, 18),
            movements: [_movement(type: 'COD Collection', amount: -470)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = _allText(tester);
      expect(text, contains('Cash collected'));
      // No order number was served, so none is drawn.
      expect(text, isNot(contains('#')));
      expect(text, isNot(contains('Order')));
    });
  });
}
