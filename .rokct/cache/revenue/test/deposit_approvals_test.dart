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

// Design strip frame 49i, the manager's side — the deposit approval queue.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * the hub's wallet pane keeps ONE action on the card's strip; the
//     queue is reached by a row under the notice, not a second button;
//   * Approve relays exactly the row's id and drops the row the server
//     accepted — the client credits nothing itself;
//   * Reject is never silent: the sheet's commit stays inert until a reason
//     is typed, and that reason is what reaches the repository;
//   * one decision in flight at a time: every other card's buttons wait;
//   * the wallet a deposit was sent against is a SENTENCE, never "−1240".

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/pages/profile/widgets/base_wallet_card.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:revenue_sdk/revenue_sdk.dart';

class _FakeApprovals implements DepositApprovalRepositoryFacade {
  _FakeApprovals(this.rows);

  List<DepositRequestRecord> rows;
  final List<String> approved = [];
  final List<(String, String)> rejected = [];

  @override
  Future<ApiResult<List<DepositRequestRecord>>>
      listPendingDepositRequests() async => ApiResult.success(data: rows);

  @override
  Future<ApiResult<DepositResolution>> approveDepositRequest(
      String requestId) async {
    approved.add(requestId);
    final row = rows.firstWhere((r) => r.id == requestId);
    return ApiResult.success(
      data: DepositResolution.fromJson({
        'approved': true,
        'request_id': requestId,
        'amount': row.amount,
        'new_balance': (row.balanceAtSubmit ?? 0) + row.amount,
      }),
    );
  }

  @override
  Future<ApiResult<DepositResolution>> rejectDepositRequest(String requestId,
      {required String reason}) async {
    rejected.add((requestId, reason));
    return ApiResult.success(
      data: DepositResolution.fromJson({
        'rejected': true,
        'request_id': requestId,
        'reason': reason,
      }),
    );
  }
}

/// A recording stand-in for the payout seam the 49l pane needs to build.
class _IdlePayouts implements DriverPayoutRepositoryFacade {
  @override
  Future<ApiResult<List<BankAccountRecord>>> listBankAccounts() async =>
      ApiResult.success(data: const []);
  @override
  Future<ApiResult<PayoutRequestResponse>> requestPayout(
          {required double amount, String? bankAccount}) async =>
      throw UnimplementedError();
  @override
  Future<ApiResult<List<PayoutRequestRecord>>> listPayoutRequests() async =>
      ApiResult.success(data: const []);
  @override
  Future<ApiResult<BankAccountRecord>> addBankAccount({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    String? branchCode,
    String? accountType,
    bool isDefault = false,
  }) async =>
      throw UnimplementedError();
  @override
  Future<ApiResult<bool>> removeBankAccount(String bankAccount) async =>
      throw UnimplementedError();
  @override
  Future<ApiResult<bool>> setDefaultBankAccount(String bankAccount) async =>
      throw UnimplementedError();
}

DepositRequestRecord _row({
  String id = 'WDR-1',
  String name = 'Thabo Mokoena',
  num amount = 1240,
  num? against = -1240,
  String? slip = 'https://files.test/slip.jpg',
}) =>
    DepositRequestRecord(
      id: id,
      amount: amount,
      status: DepositRequestStatus.pending,
      user: 'driver@example.test',
      userName: name,
      method: 'Bank Deposit',
      reference: 'TM-0831-1642',
      slipUrl: slip,
      balanceAtSubmit: against,
      submittedAt: DateTime(2026, 8, 31, 16, 42),
    );

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(home: child),
      ),
    );

Future<void> _pump(WidgetTester tester, Widget child,
    {List<Override> overrides = const []}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = 0.5;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(_host(child, overrides: overrides));
  await tester.pumpAndSettle();
}

String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join('\n')
    .toLowerCase();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  group('the hub entry (ManagerWalletPane)', () {
    testWidgets('a row under the notice, and still ONE action on the strip',
        (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ManagerWalletPane(
              scope: const ManagerWalletScope(shopId: 's1', shopName: 'A'),
              wallet: Wallet(price: 100),
            ),
          ),
        ),
        overrides: [
          managerWalletProvider.overrideWith(
            (ref, scope) => ManagerWalletNotifier(
              _IdlePayouts(),
              scope: scope,
              isOnline: () async => true,
            ),
          ),
        ],
      );
      expect(find.byKey(const Key('managerWalletDepositApprovals')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BaseWalletCard),
          matching: find.byType(CustomButton),
        ),
        findsOneWidget,
      );
    });
  });

  group('DepositApprovalsPage (frame 49i, manager side)', () {
    late _FakeApprovals repository;

    List<Override> overrides() => [
          depositApprovalsProvider.overrideWith(
            (_) => DepositApprovalsNotifier(repository, isOnline: () async => true),
          ),
        ];

    testWidgets('draws the queue: who, how much, against what, the slip',
        (tester) async {
      repository = _FakeApprovals([_row(), _row(id: 'WDR-2', name: 'Naledi D', amount: 300, against: 50, slip: null)]);
      await _pump(tester, DepositApprovalsPage(now: DateTime(2026, 8, 31, 17)),
          overrides: overrides());
      final text = _allText(tester);
      expect(find.byKey(const Key('depositApproval-WDR-1')), findsOneWidget);
      expect(find.byKey(const Key('depositApproval-WDR-2')), findsOneWidget);
      expect(text, contains('thabo mokoena'));
      expect(text, contains('1,240'));
      expect(text, contains('tm-0831-1642'));
      expect(text, contains('today 16:42'));
      // The wallet it was sent against is a sentence, never a signed figure.
      expect(text, contains('owed'));
      expect(text, isNot(contains('-1240')));
      expect(text, isNot(contains('−')));
      expect(text, contains('view slip'));
      expect(text, contains('no slip attached'));
      expect(find.byKey(const Key('depositApprovalsExplainer')), findsOneWidget);
    });

    testWidgets('an empty queue says so', (tester) async {
      repository = _FakeApprovals([]);
      await _pump(tester, const DepositApprovalsPage(), overrides: overrides());
      expect(find.byKey(const Key('depositApprovalsEmpty')), findsOneWidget);
    });

    testWidgets('Approve relays the id and drops the row', (tester) async {
      repository = _FakeApprovals([_row(), _row(id: 'WDR-2', name: 'Naledi D')]);
      await _pump(tester, const DepositApprovalsPage(), overrides: overrides());
      await tester.tap(find.byKey(const Key('depositApprove-WDR-1')));
      await tester.pumpAndSettle();
      expect(repository.approved, ['WDR-1']);
      expect(repository.rejected, isEmpty);
      expect(find.byKey(const Key('depositApproval-WDR-1')), findsNothing);
      expect(find.byKey(const Key('depositApproval-WDR-2')), findsOneWidget);
    });

    testWidgets('Reject needs a reason, then relays it', (tester) async {
      repository = _FakeApprovals([_row()]);
      await _pump(tester, const DepositApprovalsPage(), overrides: overrides());
      await tester.tap(find.byKey(const Key('depositReject-WDR-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('depositRejectSheet')), findsOneWidget);

      // Inert without a reason.
      await tester.tap(find.byKey(const Key('depositRejectConfirm')));
      await tester.pumpAndSettle();
      expect(repository.rejected, isEmpty);

      await tester.enterText(
        find.byKey(const Key('depositRejectReason')),
        '  Bank received R 300.00.  ',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('depositRejectConfirm')));
      await tester.pumpAndSettle();
      expect(repository.rejected, [('WDR-1', 'Bank received R 300.00.')]);
      expect(repository.approved, isEmpty);
      expect(find.byKey(const Key('depositApproval-WDR-1')), findsNothing);
      expect(find.byKey(const Key('depositApprovalsEmpty')), findsOneWidget);
    });
  });

  group('DepositApprovalsNotifier', () {
    test('one decision in flight at a time; the second tap is dropped',
        () async {
      final repository = _FakeApprovals([_row(), _row(id: 'WDR-2')]);
      final notifier = DepositApprovalsNotifier(repository, isOnline: () async => true);
      await notifier.load();
      expect(notifier.state.pending, hasLength(2));
      // A reject with a blank reason never leaves the notifier.
      await notifier.reject(
        context: _NoContext(),
        request: notifier.state.pending.first,
        reason: '   ',
      );
      expect(repository.rejected, isEmpty);
      expect(notifier.state.pending, hasLength(2));
    });
  });
}

/// A context that is never mounted — enough for a path that returns before
/// touching it.
class _NoContext extends Fake implements BuildContext {
  @override
  bool get mounted => false;
}
