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

// The driver's bank details — design strip frames 49n-49s.
//
// The things a later edit could quietly undo, each of which turns a working
// money screen into a broken one:
//
//   * the form enforces the THREE rules the backend has and not a fourth —
//     no digits-only mask on the account number, because nothing server-side
//     checks its shape and a mask that is not enforced sends a driver's money
//     to a typo;
//   * the honesty line under the account number says exactly that;
//   * 49n is drawn as an ABSENCE with an action, not as an error, and it
//     states that nothing moved — because the app asked before it sent, so
//     no request was fired and no hold was taken;
//   * every required refusal is marked AT ONCE, not one at a time;
//   * the default mark is singular, and `Make default` is always available,
//     because two unmarked rows make the payout unrefusably ambiguous;
//   * a row a live payout names cannot be removed, and says why in the row;
//   * 49r draws the SUBTRACTION, because the balance dropped at request time;
//   * nothing on 49r is green and no reference is shown.
//
// Every seeded value here is invented. This is a banking form.

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/bank_field.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/bank_grammar.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/no_bank_account_sheet.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/payout_sent_sheet.dart';

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

/// One account exactly as `list_bank_accounts` serves it. Invented bank,
/// invented holder, invented number — none of these name a real person or a
/// real account.
Map<String, dynamic> _accountJson({
  String id = 'acct-1',
  String holder = 'Naledi Dlamini',
  String bank = 'Thrift Union',
  String number = '9911002233',
  String? branch = '470010',
  String? type = 'Savings',
  dynamic isDefault = 1,
}) =>
    {
      'id': id,
      'account_holder_name': holder,
      'bank_name': bank,
      'account_number': number,
      'branch_code': branch,
      'account_type': type,
      'is_default': isDefault,
    };

BankAccountRecord _account({
  String id = 'acct-1',
  String bank = 'Thrift Union',
  String number = '9911002233',
  bool isDefault = true,
}) =>
    BankAccountRecord.fromJson(
      _accountJson(id: id, bank: bank, number: number, isDefault: isDefault ? 1 : 0),
    );

PayoutRequestRecord _liveRequestAgainst(String accountId) =>
    PayoutRequestRecord.fromJson({
      'id': 'req-1',
      'amount': 3860,
      'status': 'Requested',
      'requested_at': '2026-08-31 17:20:00',
      'resolved_at': null,
      'bank_account': {
        'id': accountId,
        'account_holder_name': 'Naledi Dlamini',
        'bank_name': 'Thrift Union',
        'account_number': '9911002233',
        'branch_code': '470010',
        'account_type': 'Savings',
      },
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  group('the record (49o/49q)', () {
    test('it parses every field the endpoint serves', () {
      final account = BankAccountRecord.fromJson(_accountJson());
      expect(account.id, 'acct-1');
      expect(account.accountHolderName, 'Naledi Dlamini');
      expect(account.bankName, 'Thrift Union');
      expect(account.accountNumber, '9911002233');
      expect(account.branchCode, '470010');
      expect(account.accountType, 'Savings');
      expect(account.isDefault, isTrue);
    });

    test('the optional pair is null, not empty, when the row omits it', () {
      final account =
          BankAccountRecord.fromJson(_accountJson(branch: '', type: null));
      expect(account.branchCode, isNull);
      expect(account.accountType, isNull);
    });

    test('the default flag survives every shape Frappe can send it in', () {
      for (final truthy in <dynamic>[1, '1', true, 'true']) {
        expect(
          BankAccountRecord.fromJson(_accountJson(isDefault: truthy)).isDefault,
          isTrue,
          reason: 'a default account must never read as unmarked ($truthy)',
        );
      }
      for (final falsy in <dynamic>[0, '0', false, null, '']) {
        expect(
          BankAccountRecord.fromJson(_accountJson(isDefault: falsy)).isDefault,
          isFalse,
        );
      }
    });

    test('a non-list answer parses to no rows, never to a throw', () {
      expect(BankAccountRecord.listFrom(null), isEmpty);
      expect(BankAccountRecord.listFrom('nope'), isEmpty);
      expect(BankAccountRecord.listFrom(<dynamic>[_accountJson()]).length, 1);
    });

    test('the request row carries the account id the removal check needs', () {
      expect(_liveRequestAgainst('acct-7').bankAccountId, 'acct-7');
    });
  });

  group('the three rules, and not a fourth (49o/49p)', () {
    test('a required field refuses blank and whitespace-only', () {
      for (final blank in <String?>[null, '', '   ', '\t ']) {
        expect(
          requiredFieldProblemKey(BankField.accountNumber, blank),
          isNotNull,
          reason: '_required_text strips then throws (payout.py:108-115)',
        );
      }
    });

    test('a required field refuses only past 140 characters', () {
      expect(
        requiredFieldProblemKey(
          BankField.bankName,
          'x' * kMaxBankFieldLength,
        ),
        isNull,
        reason: 'exactly at the ceiling still saves',
      );
      expect(
        requiredFieldProblemKey(
          BankField.bankName,
          'x' * (kMaxBankFieldLength + 1),
        ),
        isNotNull,
      );
    });

    test('the optional pair accepts blank and carries only the ceiling', () {
      expect(optionalFieldProblemKey(BankField.branchCode, ''), isNull);
      expect(optionalFieldProblemKey(BankField.branchCode, '   '), isNull);
      expect(
        optionalFieldProblemKey(
          BankField.branchCode,
          'x' * (kMaxBankFieldLength + 1),
        ),
        isNotNull,
      );
    });

    test(
      'NOTHING checks the shape of the account number — no digit rule, no '
      'length rule, no checksum',
      () {
        // The load-bearing assertion of this whole file. `add_bank_account`
        // has no format validation, `_required_text` has none, and the
        // controller is a bare `pass`. A client-side mask would be a check
        // the backend has not written, and a driver who trusts it will send
        // his money to a typo. If someone adds a shape rule, it belongs in
        // `add_bank_account` FIRST — and this test should then be changed
        // deliberately, not deleted quietly.
        for (final oddButAccepted in <String>[
          '1',
          '12 34 56',
          'GB29 NWBK 6016 1331 9268 19',
          'abc-123',
          '000000000000000000',
        ]) {
          expect(
            requiredFieldProblemKey(BankField.accountNumber, oddButAccepted),
            isNull,
            reason: 'the backend accepts it, so the form must not refuse it',
          );
        }
      },
    );

    test('the branch code is not validated either', () {
      for (final anything in <String>['470010', 'ABC', '1', 'x y z']) {
        expect(
          optionalFieldProblemKey(BankField.branchCode, anything),
          isNull,
        );
      }
    });

    test('the account type is the doctype Select, blank included', () {
      expect(kBankAccountTypes, <String>['Cheque', 'Savings', 'Transmission']);
      for (final type in kBankAccountTypes) {
        expect(isAcceptableAccountType(type), isTrue);
      }
      expect(isAcceptableAccountType(null), isTrue, reason: 'blank is real');
      expect(isAcceptableAccountType(''), isTrue);
      expect(isAcceptableAccountType('Current'), isFalse);
    });

    test('every missing required field is named at once, in signature order',
        () {
      expect(
        missingRequiredFields(
          accountHolderName: '',
          bankName: 'Thrift Union',
          accountNumber: '  ',
        ),
        <BankField>[BankField.accountHolderName, BankField.accountNumber],
        reason: 'revealing one error at a time turns a form into a corridor',
      );
    });

    test('save is held until the form can actually succeed', () {
      expect(
        canSaveBankAccount(
          accountHolderName: 'Naledi Dlamini',
          bankName: 'Thrift Union',
          accountNumber: '9911002233',
        ),
        isTrue,
      );
      expect(
        canSaveBankAccount(
          accountHolderName: 'Naledi Dlamini',
          bankName: '',
          accountNumber: '9911002233',
        ),
        isFalse,
      );
      expect(
        canSaveBankAccount(
          accountHolderName: 'Naledi Dlamini',
          bankName: 'Thrift Union',
          accountNumber: '9911002233',
          accountType: 'Current',
        ),
        isFalse,
      );
    });
  });

  group('the refusals the client can predict (49s)', () {
    test('the duplicate is keyed on number + bank, as the backend keys it',
        () {
      final existing = [_account()];
      expect(
        isDuplicateAccount(
          existing,
          accountNumber: ' 9911002233 ',
          bankName: 'thrift union',
        ),
        isTrue,
        reason: 'stripped and case-folded, matching what the endpoint stores',
      );
      expect(
        isDuplicateAccount(
          existing,
          accountNumber: '9911002233',
          bankName: 'Harbour Mutual',
        ),
        isFalse,
        reason: 'same number at a different bank is a different account',
      );
    });

    test('removal is blocked only by a LIVE payout naming that account', () {
      final live = [_liveRequestAgainst('acct-1')];
      expect(isRemovalBlocked('acct-1', live), isTrue);
      expect(isRemovalBlocked('acct-2', live), isFalse);
      expect(isRemovalBlocked('acct-1', const []), isFalse);
    });

    test('a resolved payout does not block removal', () {
      final paid = PayoutRequestRecord.fromJson({
        'id': 'req-2',
        'amount': 100,
        'status': 'Paid',
        'bank_account': {'id': 'acct-1'},
      });
      expect(isRemovalBlocked('acct-1', [paid]), isFalse);
    });
  });

  group('choosing the account a payout names (49q)', () {
    test('the marked default wins', () {
      final accounts = [
        _account(id: 'a', isDefault: false),
        _account(id: 'b', number: '4417009988', isDefault: true),
      ];
      expect(defaultAccount(accounts)?.id, 'b');
    });

    test('a lone unmarked account is used — exactly as _default_account does',
        () {
      expect(
        defaultAccount([_account(id: 'a', isDefault: false)])?.id,
        'a',
      );
    });

    test(
      'TWO unmarked accounts resolve to nothing, because the server refuses '
      'that case too',
      () {
        final accounts = [
          _account(id: 'a', isDefault: false),
          _account(id: 'b', number: '4417009988', isDefault: false),
        ];
        expect(
          defaultAccount(accounts),
          isNull,
          reason: 'picking one here would be refused for a reason the driver '
              'could never see (payout.py:137-157)',
        );
      },
    );

    test('no accounts resolve to nothing', () {
      expect(defaultAccount(const []), isNull);
    });
  });

  group('showing an account back to him (49q)', () {
    test('the number is masked to its last four', () {
      expect(maskAccountNumber('9911002233'), '•••• 2233');
    });

    test('a short number is not padded into a false shape', () {
      expect(maskAccountNumber('88'), '88');
      expect(maskAccountNumber(''), '');
    });

    test('the summary omits a blank type rather than inventing one', () {
      expect(accountSummary(_account()), 'Thrift Union · Savings');
      expect(
        accountSummary(
          BankAccountRecord.fromJson(_accountJson(type: null)),
        ),
        'Thrift Union',
      );
    });
  });

  group('the field widget (49p)', () {
    testWidgets('the honesty line is drawn under the account number',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankFormField(
            fieldKey: const Key('n'),
            label: 'Account number',
            controller: TextEditingController(),
            isRequired: true,
            helperKey: 'nothing_checks_the_shape_of_this_number_'
                'copy_it_exactly_as_your_bank_shows_it',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _allText(tester).toLowerCase(),
        contains('nothing checks the shape of this number'),
      );
    });

    testWidgets('the refusal names the field, and the border goes red',
        (tester) async {
      await tester.pumpWidget(
        _host(
          BankFormField(
            fieldKey: const Key('n'),
            label: 'Account number',
            controller: TextEditingController(),
            isRequired: true,
            problemKey: 'please_enter_the_account_number',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _allText(tester).toLowerCase(),
        contains('please enter the account number'),
      );
    });

    testWidgets('the 140 ceiling shows as a live count only AT the limit',
        (tester) async {
      final controller = TextEditingController(text: 'x' * 12);
      await tester.pumpWidget(
        _host(
          BankFormField(
            fieldKey: const Key('b'),
            label: 'Bank',
            controller: controller,
            isRequired: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_allText(tester), isNot(contains('140 / 140')));

      controller.text = 'x' * kMaxBankFieldLength;
      await tester.pumpWidget(
        _host(
          BankFormField(
            fieldKey: const Key('b'),
            label: 'Bank',
            controller: controller,
            isRequired: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_allText(tester), contains('140 / 140'));
    });

    testWidgets('an optional field says so on its face', (tester) async {
      await tester.pumpWidget(
        _host(
          BankFormField(
            fieldKey: const Key('br'),
            label: 'Branch code',
            controller: TextEditingController(),
            isRequired: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_allText(tester).toLowerCase(), contains('optional'));
    });
  });

  group('the no-account state (49n)', () {
    Widget sheet({num available = 3860}) => _host(
          NoBankAccountSheet(
            available: available,
            onAddBankAccount: () {},
            onDismiss: () {},
          ),
        );

    testWidgets('it opens onto the reason, not onto an amount field',
        (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noBankAccountReason')), findsOneWidget);
      expect(
        _allText(tester).toLowerCase(),
        contains('where to pay you'),
      );
    });

    testWidgets('the primary action is Add a bank account, not Retry',
        (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('noBankAccountAdd')), findsOneWidget);
      final text = _allText(tester).toLowerCase();
      expect(text, contains('add a bank account'));
      expect(text, isNot(contains('retry')));
      expect(text, isNot(contains('try again')));
    });

    testWidgets(
      'it states that NOTHING moved — no request sent, no hold taken',
      (tester) async {
        await tester.pumpWidget(sheet());
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('noBankAccountUntouchedBalance')),
          findsOneWidget,
        );
        final text = _allText(tester).toLowerCase();
        expect(text, contains('nothing has moved'));
        expect(text, contains('no request was sent'));
      },
    );

    testWidgets('the balance it repeats is the one the page already held',
        (tester) async {
      await tester.pumpWidget(sheet(available: 1234));
      await tester.pumpAndSettle();
      expect(_allText(tester), contains('1,234'));
    });

    testWidgets('it never speaks in the server voice', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      final text = _allText(tester).toLowerCase();
      for (final leak in <String>[
        'payout bank account',
        'request_payout',
        'frappe',
        'validation',
        'error',
        'failed',
      ]) {
        expect(text, isNot(contains(leak)), reason: 'leaked: $leak');
      }
    });
  });

  group('sent (49r)', () {
    Widget sheet({
      num before = 3860,
      num amount = 3860,
      num now = 0,
      BankAccountRecord? account,
    }) =>
        _host(
          PayoutSentSheet(
            balanceBefore: before,
            amount: amount,
            newBalance: now,
            account: account,
            onDone: () {},
          ),
        );

    testWidgets('it draws the subtraction: before, out, now', (tester) async {
      await tester.pumpWidget(sheet(before: 3860, amount: 3860, now: 0));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('payoutSentReconciliation')),
        findsOneWidget,
      );
      final text = _allText(tester).toLowerCase();
      expect(text, contains('balance before'));
      expect(text, contains('out on this request'));
      expect(text, contains('balance now'));
    });

    testWidgets('the figures are the ones the server reported', (tester) async {
      await tester.pumpWidget(sheet(before: 1000, amount: 250, now: 750));
      await tester.pumpAndSettle();
      final text = _allText(tester);
      expect(text, contains('1,000'));
      expect(text, contains('250'));
      expect(text, contains('750'));
    });

    testWidgets('it says a person still has to approve it', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payoutSentPendingCard')), findsOneWidget);
      expect(
        _allText(tester).toLowerCase(),
        contains('still has to approve'),
      );
    });

    testWidgets('it never claims the payout is done', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      final text = _allText(tester).toLowerCase();
      for (final done in <String>['paid out', 'complete', 'success']) {
        expect(text, isNot(contains(done)), reason: 'claimed: $done');
      }
    });

    testWidgets('no reference is shown, because there is no naming series',
        (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(_allText(tester).toLowerCase(), isNot(contains('reference')));
    });

    testWidgets('no cancel affordance is offered here', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      // `cancel_payout_request` exists and works, but who may cancel and
      // until when is unsettled policy that frame 49k flagged — so this
      // sheet offers exactly ONE action, and it is Done.
      //
      // The word "cancelled" DOES appear, in the credit-back promise, and
      // must: it is how the driver learns the money comes back. What must
      // not appear is a control that acts on it.
      expect(find.byType(CustomButton), findsOneWidget);
      expect(find.byKey(const Key('payoutSentDone')), findsOneWidget);
      expect(
        _allText(tester).toLowerCase(),
        contains('cancelled'),
        reason: 'the credit-back promise names cancellation on purpose',
      );
      expect(
        tester
            .widgetList<CustomButton>(find.byType(CustomButton))
            .map((b) => b.title.toLowerCase())
            .where((title) => title.contains('cancel')),
        isEmpty,
      );
    });

    testWidgets(
      'the bank block says the details were COPIED onto the request',
      (tester) async {
        await tester.pumpWidget(sheet(account: _account()));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('payoutSentBankBlock')), findsOneWidget);
        final text = _allText(tester).toLowerCase();
        expect(text, contains('copied onto this request'));
        expect(
          text,
          contains('2233'),
          reason: 'the masked tail identifies the account',
        );
        expect(
          text,
          isNot(contains('9911002233')),
          reason: 'the full number is never drawn on a row he is not typing',
        );
      },
    );

    testWidgets('with no account it still draws the arithmetic', (tester) async {
      await tester.pumpWidget(sheet());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payoutSentBankBlock')), findsNothing);
      expect(
        find.byKey(const Key('payoutSentReconciliation')),
        findsOneWidget,
      );
    });
  });
}
