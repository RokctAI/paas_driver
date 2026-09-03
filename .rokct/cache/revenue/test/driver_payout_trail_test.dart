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

// The payout trail — design strip frame 49k.
//
// The things a later edit could quietly undo:
//
//   * the trail FORKS: Paid and Rejected are alternatives hanging off the
//     one live Requested node, never steps in a line, because a line would
//     promise that every request eventually pays;
//   * the live card repeats the debit-at-request disclosure, because this
//     is the screen he returns to hours later;
//   * a rejected or cancelled row says the money went BACK — and says
//     nothing about why it was rejected, because the doctype stores no
//     reason and inventing one would be worse than the silence;
//   * a failed read says one friendly line and never the cause;
//   * no cancel affordance is offered: who may cancel, and until when, is
//     unsettled policy.

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';
import 'package:revenue_sdk/src/common/presentation/payouts/payout_history_list.dart';
import 'package:revenue_sdk/src/common/presentation/payouts/payout_status_trail.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join('\n');

/// One row exactly as `list_payout_requests` serves it — a bare list of
/// maps with the banking details nested under `bank_account`.
Map<String, dynamic> _row({
  String id = 'req-1',
  num amount = 3860,
  String status = 'Requested',
  String requestedAt = '2026-08-31 17:20:00',
  String bank = 'Thrift Union',
  String account = '9911002233',
}) =>
    {
      'id': id,
      'amount': amount,
      'status': status,
      'requested_at': requestedAt,
      'resolved_at': null,
      'bank_account': {
        'id': 'acct-1',
        'account_holder_name': 'Naledi Dlamini',
        'bank_name': bank,
        'account_number': account,
        'branch_code': '470010',
        'account_type': 'Savings',
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  group('list_payout_requests answers a BARE list', () {
    test('every row parses, and a non-list parses to none', () {
      final rows = PayoutRequestRecord.listFrom([
        _row(id: 'a'),
        _row(id: 'b', status: 'Paid'),
      ]);
      expect(rows.length, 2);
      expect(rows.first.id, 'a');
      expect(rows.first.amount, 3860);
      expect(rows.first.bankName, 'Thrift Union');

      // The wallet statement's `{"data": [...]}` envelope is a DIFFERENT
      // shape; handing it here must not half-parse into a fake trail.
      expect(PayoutRequestRecord.listFrom({'data': []}), isEmpty);
      expect(PayoutRequestRecord.listFrom(null), isEmpty);
      expect(PayoutRequestRecord.listFrom(const ['not a row']), isEmpty);
    });
  });

  group('the status trail (chip 987)', () {
    testWidgets('the live node forks to two alternatives, not to two steps',
        (tester) async {
      await tester.pumpWidget(
        _host(
          PayoutStatusTrail(
            request: PayoutRequestRecord.fromJson(_row()),
            now: DateTime(2026, 8, 31, 18),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = _allText(tester);
      expect(text, contains('Requested'));
      expect(text, contains('Paid into your account'));
      expect(text, contains('Rejected'));
      expect(
        tester
            .widget<Text>(find.byKey(const Key('payoutStatusTrailAmount')))
            .data,
        contains('3,860'),
      );
    });

    testWidgets('it repeats the debit-at-request disclosure on its face',
        (tester) async {
      await tester.pumpWidget(
        _host(
          PayoutStatusTrail(
            request: PayoutRequestRecord.fromJson(_row()),
            now: DateTime(2026, 8, 31, 18),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notice = tester
          .widget<Text>(find.byKey(const Key('payoutStatusTrailDebitNotice')))
          .data!;
      expect(notice, contains('Today 17:20'));
      expect(notice.toLowerCase(), contains('already taken off your balance'));
    });

    testWidgets('a request with no timestamp still states the disclosure',
        (tester) async {
      await tester.pumpWidget(
        _host(
          PayoutStatusTrail(
            request: PayoutRequestRecord.fromJson({
              'id': 'x',
              'amount': 10,
              'status': 'Requested',
            }),
            now: DateTime(2026, 8, 31, 18),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('payoutStatusTrailDebitNotice')))
            .data!
            .toLowerCase(),
        contains('already taken off your balance'),
      );
    });
  });

  group('the payout history (chip 988)', () {
    testWidgets('each row carries the amount, the date and the snapshot bank',
        (tester) async {
      await tester.pumpWidget(
        _host(
          PayoutHistoryList(
            loadedOnce: true,
            now: DateTime(2026, 8, 31, 18),
            requests: PayoutRequestRecord.listFrom([
              _row(id: 'a', amount: 3860, status: 'Requested'),
              _row(
                id: 'b',
                amount: 2400,
                status: 'Paid',
                requestedAt: '2026-08-24 16:05:00',
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = _allText(tester);
      expect(text, contains('3,860'));
      expect(text, contains('2,400'));
      expect(text, contains('24 Aug 16:05'));
      expect(text, contains('Thrift Union •••• 2233'));
      // Never the whole account number.
      expect(text, isNot(contains('9911002233')));
      expect(text, contains('Requested'));
      expect(text, contains('Paid'));
    });

    testWidgets('a rejected row says the money went back, and says no reason',
        (tester) async {
      await tester.pumpWidget(
        _host(
          PayoutHistoryList(
            loadedOnce: true,
            now: DateTime(2026, 8, 31, 18),
            requests: PayoutRequestRecord.listFrom([
              _row(
                id: 'c',
                amount: 1800,
                status: 'Rejected',
                requestedAt: '2026-08-17 12:31:00',
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payoutCreditedBackNote')), findsOneWidget);
      final text = _allText(tester);
      expect(text, contains('1,800'));
      expect(text.toLowerCase(),
          contains('was put straight back into your balance'));
      // The doctype stores no rejection reason; none may be invented.
      expect(text.toLowerCase(), isNot(contains('did not match')));
      expect(text.toLowerCase(), isNot(contains('reason')));
    });

    testWidgets('a paid row is NOT credited back', (tester) async {
      await tester.pumpWidget(
        _host(
          PayoutHistoryList(
            loadedOnce: true,
            now: DateTime(2026, 8, 31, 18),
            requests: PayoutRequestRecord.listFrom([
              _row(id: 'd', amount: 2400, status: 'Paid'),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payoutCreditedBackNote')), findsNothing);
    });

    testWidgets('a cancelled row is credited back on the same latch',
        (tester) async {
      await tester.pumpWidget(
        _host(
          PayoutHistoryList(
            loadedOnce: true,
            now: DateTime(2026, 8, 31, 18),
            requests: PayoutRequestRecord.listFrom([
              _row(id: 'e', amount: 900, status: 'Cancelled'),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payoutCreditedBackNote')), findsOneWidget);
    });

    testWidgets('no cancel affordance is offered anywhere on the trail',
        (tester) async {
      await tester.pumpWidget(
        _host(
          PayoutHistoryList(
            loadedOnce: true,
            now: DateTime(2026, 8, 31, 18),
            requests: PayoutRequestRecord.listFrom([_row()]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The status word may appear as a STATE, but nothing invites a tap.
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('an empty trail is only stated once a read has landed',
        (tester) async {
      await tester.pumpWidget(
        _host(const PayoutHistoryList(requests: [])),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('payoutHistoryEmpty')))
            .data!
            .toLowerCase(),
        contains('loading'),
      );

      await tester.pumpWidget(
        _host(const PayoutHistoryList(requests: [], loadedOnce: true)),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('payoutHistoryEmpty')))
            .data!
            .toLowerCase(),
        contains('withdrawn'),
      );
    });

    testWidgets('a failed read says one friendly line, not the cause',
        (tester) async {
      await tester.pumpWidget(
        _host(const PayoutHistoryList(
          requests: [],
          failed: true,
          loadedOnce: true,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payoutHistoryFailed')), findsOneWidget);
      final text = _allText(tester).toLowerCase();
      for (final leak in const [
        'exception',
        '417',
        'dioerror',
        'bank account',
        'not configured',
        'insufficient',
      ]) {
        expect(text, isNot(contains(leak)));
      }
    });
  });
}
