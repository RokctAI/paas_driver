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

// Design strip frame 49l — the manager withdraws.
//
// The things a later edit could quietly undo:
//
//   * the pane is the approved wallet card with ONE action on its strip
//     (chip 989) and the debit-at-request notice under it (chip 986);
//   * an empty or negative balance leaves the action inert and sends
//     nothing;
//   * a tap reads the bank accounts BEFORE anything opens (frame 49n's
//     order): with none on file the manager meets the explanation and NO
//     request is sent, nothing is held;
//   * with an account on file the fleet-keypad sheet opens, and the
//     request hands the typed amount and the NAMED account to the
//     repository — the sheet owns no truth about the money;
//   * an accepted request states the subtraction (frame 49r) and the card
//     draws the post-hold balance the server reported.

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

/// A recording stand-in for the ONE payout seam. Invented bank, invented
/// holder, invented number — none of these name a real person or account.
class _FakePayoutRepository implements DriverPayoutRepositoryFacade {
  _FakePayoutRepository({this.accounts = const [], this.newBalance = 1000});

  List<BankAccountRecord> accounts;
  num newBalance;
  int listCalls = 0;
  final List<({double amount, String? bankAccount})> payoutCalls = [];

  @override
  Future<ApiResult<List<BankAccountRecord>>> listBankAccounts() async {
    listCalls++;
    return ApiResult.success(data: accounts);
  }

  @override
  Future<ApiResult<PayoutRequestResponse>> requestPayout({
    required double amount,
    String? bankAccount,
  }) async {
    payoutCalls.add((amount: amount, bankAccount: bankAccount));
    return ApiResult.success(
      data: PayoutRequestResponse.fromJson({
        'success': true,
        'request_id': 'req-49l',
        'amount': amount,
        'new_balance': newBalance,
      }),
    );
  }

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

BankAccountRecord _account({String id = 'acct-1', bool isDefault = true}) =>
    BankAccountRecord.fromJson({
      'id': id,
      'account_holder_name': 'Naledi Dlamini',
      'bank_name': 'Thrift Union',
      'account_number': '9911002233',
      'branch_code': '470010',
      'account_type': 'Savings',
      'is_default': isDefault ? 1 : 0,
    });

const _scope = ManagerWalletScope(shopId: 'shop-7', shopName: 'Corner Kitchen');

Widget _host(_FakePayoutRepository repository, Widget child) => ProviderScope(
      overrides: [
        managerWalletProvider.overrideWith(
          (ref, scope) => ManagerWalletNotifier(
            repository,
            scope: scope,
            isOnline: () async => true,
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );

Future<void> _pump(
  WidgetTester tester,
  _FakePayoutRepository repository, {
  num balance = 1250,
}) async {
  // A tall, 1:1 surface: ScreenUtil scales against the design size, and
  // the default 800x600 test view pushes the keypad's lower rows off it.
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // The test font draws every glyph as a full-size square, so a label and
  // a figure that share one row at 1:1 (the sent sheet's reconciliation
  // rows) overflow here and nowhere else. Halving the text scale keeps
  // the layout honest without touching the shipped sheets.
  tester.platformDispatcher.textScaleFactorTestValue = 0.5;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    _host(
      repository,
      ManagerWalletPane(scope: _scope, wallet: Wallet(price: balance)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final ch in digits.split('')) {
    final id = ch == '.' ? 'moneyKeyDecimal' : 'moneyKey$ch';
    await tester.ensureVisible(find.byKey(Key(id)));
    await tester.tap(find.byKey(Key(id)));
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  group('ManagerWalletScope', () {
    test('is a value: equal scopes key the same provider', () {
      const a = ManagerWalletScope(shopId: 's1', shopName: 'A');
      const b = ManagerWalletScope(shopId: 's1', shopName: 'A');
      const c = ManagerWalletScope(shopId: 's2', shopName: 'A');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('ManagerWalletPane (frame 49l)', () {
    testWidgets('renders the approved card with one action and the notice',
        (tester) async {
      final repository = _FakePayoutRepository();
      await _pump(tester, repository);
      expect(find.byType(BaseWalletCard), findsOneWidget);
      expect(find.byKey(const Key('managerWithdrawAction')), findsOneWidget);
      expect(find.byKey(const Key('managerWalletDebitNotice')), findsOneWidget);
      // The action is the card's ONLY action: exactly one button on the
      // strip, and nothing has been asked of the repository yet.
      expect(
        find.descendant(
          of: find.byType(BaseWalletCard),
          matching: find.byType(CustomButton),
        ),
        findsOneWidget,
      );
      expect(repository.listCalls, 0);
    });

    testWidgets('an empty or negative balance leaves the action inert',
        (tester) async {
      for (final balance in const <num>[0, -320.75]) {
        final repository = _FakePayoutRepository(accounts: [_account()]);
        await _pump(tester, repository, balance: balance);
        await tester.tap(find.byKey(const Key('managerWithdrawAction')));
        await tester.pumpAndSettle();
        expect(repository.listCalls, 0, reason: 'balance $balance');
        expect(repository.payoutCalls, isEmpty, reason: 'balance $balance');
        expect(find.byType(WithdrawSheet), findsNothing);
      }
    });

    testWidgets(
        'reads the accounts first and, with none on file, explains instead '
        'of sending (frame 49n)', (tester) async {
      final repository = _FakePayoutRepository();
      await _pump(tester, repository);
      await tester.tap(find.byKey(const Key('managerWithdrawAction')));
      await tester.pumpAndSettle();
      expect(repository.listCalls, 1);
      expect(find.byType(NoBankAccountSheet), findsOneWidget);
      expect(find.byType(WithdrawSheet), findsNothing);
      // No request was sent and nothing was held.
      expect(repository.payoutCalls, isEmpty);
    });

    testWidgets(
        'with an account on file the sheet opens and the request delegates '
        'the typed amount and the named account to the repository',
        (tester) async {
      final repository = _FakePayoutRepository(
        accounts: [_account(id: 'acct-1')],
        newBalance: 1000,
      );
      await _pump(tester, repository, balance: 1250);
      await tester.tap(find.byKey(const Key('managerWithdrawAction')));
      await tester.pumpAndSettle();
      expect(repository.listCalls, 1);
      expect(find.byType(WithdrawSheet), findsOneWidget);
      expect(find.byKey(const Key('withdrawBankBlock')), findsOneWidget);

      await _type(tester, '250');
      await tester.ensureVisible(find.byKey(const Key('withdrawSubmit')));
      await tester.tap(find.byKey(const Key('withdrawSubmit')));
      await tester.pumpAndSettle();

      expect(repository.payoutCalls, hasLength(1));
      expect(repository.payoutCalls.single.amount, 250.0);
      // Named EXPLICITLY, never left to the server's default.
      expect(repository.payoutCalls.single.bankAccount, 'acct-1');

      // Frame 49r: the subtraction is stated, and the card now draws the
      // post-hold balance the server reported, not the host's snapshot.
      expect(find.byType(PayoutSentSheet), findsOneWidget);
      expect(find.byType(WithdrawSheet), findsNothing);
      final card = tester.widget<BaseWalletCard>(find.byType(BaseWalletCard));
      expect(card.wallet?.price, 1000);
    });

    testWidgets('a request in flight cannot be fired twice', (tester) async {
      final repository = _FakePayoutRepository(accounts: [_account()]);
      final scope = _scope;
      final notifier = ManagerWalletNotifier(
        repository,
        scope: scope,
        isOnline: () async => true,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            managerWalletProvider.overrideWith((ref, _) => notifier),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MaterialApp(
              home: Builder(
                builder: (context) => TextButton(
                  key: const Key('fire'),
                  onPressed: () {
                    notifier.requestPayout(context: context, amount: 10);
                    notifier.requestPayout(context: context, amount: 10);
                  },
                  child: const Text('fire'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fire')));
      await tester.pumpAndSettle();
      expect(repository.payoutCalls, hasLength(1));
      expect(notifier.state.balanceAfterHold, 1000);
      expect(notifier.state.lastRequestId, 'req-49l');
    });
  });
}
