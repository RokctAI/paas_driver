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

// The arithmetic and the wording rules behind the driver's money planes
// (design strip frames 49f and 49k).
//
// The things a later edit could quietly undo:
//
//   * a NEGATIVE balance is a sentence, never a signed number, and never an
//     error state — it is deliberate and normal for a driver;
//   * a wallet movement's direction comes from the SIGN first and the type
//     second, because the ledger has two writers that disagree about the
//     sign — get this wrong and a cash debit draws as a credit;
//   * only a still-Requested payout counts as money that is out;
//   * Rejected and Cancelled are credited back; Paid is not.

import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/wallet_movement.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/wallet_grammar.dart';

PayoutRequestRecord _request({
  String id = 'req-1',
  num amount = 100,
  String status = 'Requested',
  String? requestedAt,
  String? bankName = 'Thrift Union',
  String? accountNumber = '9911002233',
}) =>
    PayoutRequestRecord.fromJson({
      'id': id,
      'amount': amount,
      'status': status,
      'requested_at': requestedAt,
      'bank_account': {
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder_name': 'Naledi Dlamini',
        'account_type': 'Savings',
      },
    });

void main() {
  group('the balance speaks in sentences', () {
    test('below zero is owing, and that is a normal driver state', () {
      expect(toneFor(-1240), BalanceTone.owing);
      expect(balanceLeadKey(BalanceTone.owing), 'you_owe');
      expect(
        withdrawBlockedKey(-1240),
        'withdraw_is_unavailable_while_you_owe_money',
      );
      expect(canWithdraw(-1240), isFalse);
    });

    test('exactly zero is empty, not owing', () {
      expect(toneFor(0), BalanceTone.empty);
      expect(withdrawBlockedKey(0), 'you_have_nothing_to_withdraw_yet');
      expect(canWithdraw(0), isFalse);
    });

    test('above zero is the only state that can withdraw', () {
      expect(toneFor(0.01), BalanceTone.available);
      expect(withdrawBlockedKey(3860), isNull);
      expect(canWithdraw(3860), isTrue);
    });
  });

  group('movement direction survives both ledger writers', () {
    test('commerce writes a SIGNED amount: the cash debit is money out', () {
      // settlement.py:479-488 — the collected cash, typed COD Collection
      // with a negative amount.
      final movement = WalletMovement.fromJson({
        'transaction_type': 'COD Collection',
        'amount': -470,
      });
      expect(movement.isCredit, isFalse);
      expect(movement.magnitude, 470);
    });

    test('commerce writes the delivery fee as a POSITIVE Topup: money in',
        () {
      final movement = WalletMovement.fromJson({
        'transaction_type': 'Topup',
        'amount': 38.5,
      });
      expect(movement.isCredit, isTrue);
      expect(movement.magnitude, 38.5);
    });

    test('the commission is a NEGATIVE Withdraw: money out', () {
      final movement = WalletMovement.fromJson({
        'transaction_type': 'Withdraw',
        'amount': -4.5,
      });
      expect(movement.isCredit, isFalse);
    });

    test('wallet writes an UNSIGNED payout: still money out, by type', () {
      // payment.py:1372-1387 stores abs(amount); only the type says the
      // money left. This is the case a sign-only rule would draw wrong.
      final movement = WalletMovement.fromJson({
        'transaction_type': 'Payout',
        'amount': 1500,
      });
      expect(movement.isCredit, isFalse);
      expect(movement.magnitude, 1500);
    });

    test('an unknown type with a positive amount reads as money in', () {
      final movement = WalletMovement.fromJson({
        'transaction_type': 'Something New',
        'amount': 12,
      });
      expect(movement.isCredit, isTrue);
    });

    test('a string amount and a missing amount both parse safely', () {
      expect(
        WalletMovement.fromJson({'amount': '25.5', 'transaction_type': 'Topup'})
            .magnitude,
        25.5,
      );
      expect(WalletMovement.fromJson(const {}).magnitude, 0);
    });

    test('creation parses out of the Frappe datetime shape', () {
      final movement =
          WalletMovement.fromJson({'creation': '2026-08-28 11:40:00'});
      expect(movement.at, DateTime(2026, 8, 28, 11, 40));
    });
  });

  group('movement labels never invent a narrative', () {
    test('the row sentence wins when the server sends one', () {
      final movement = WalletMovement.fromJson({
        'transaction_type': 'COD Collection',
        'description': 'Cash collected from customer of Order ORD-0001',
      });
      expect(
        movementDescription(movement),
        'Cash collected from customer of Order ORD-0001',
      );
    });

    test('with no sentence the label is coarse, never guessed', () {
      // Topup carries BOTH a real top-up and a delivery-fee credit, so it
      // is labelled money in and nothing more specific.
      expect(
        movementTypeKey(WalletMovement.fromJson({'transaction_type': 'Topup'})),
        'wallet_credit',
      );
      expect(
        movementTypeKey(
            WalletMovement.fromJson({'transaction_type': 'COD Collection'})),
        'cash_collected',
      );
      expect(
        movementTypeKey(
            WalletMovement.fromJson({'transaction_type': 'Payout'})),
        'payout_to_your_bank',
      );
    });

    test('an unmapped type falls through to the ledger word itself', () {
      expect(
        movementTypeKey(
            WalletMovement.fromJson({'transaction_type': 'Escrow Release'})),
        'Escrow Release',
      );
    });

    test('a blank description does not beat the type', () {
      final movement = WalletMovement.fromJson({
        'transaction_type': 'Topup',
        'description': '   ',
      });
      expect(movementDescription(movement), isNull);
    });
  });

  group('get_wallet_history answers a DATA envelope', () {
    test('the rows under `data` parse; the bare list shape does not', () {
      final rows = WalletMovement.listFrom([
        {'transaction_type': 'Topup', 'amount': 900},
        {'transaction_type': 'Payout', 'amount': 1500},
      ]);
      expect(rows.length, 2);
      expect(rows.first.isCredit, isTrue);
      expect(rows.last.isCredit, isFalse);

      expect(WalletMovement.listFrom(null), isEmpty);
      expect(WalletMovement.listFrom({'data': []}), isEmpty);
      expect(WalletMovement.listFrom(const ['not a row']), isEmpty);
    });
  });

  group('payout records', () {
    test('only a Requested row is live, and only live money is out', () {
      final requests = [
        _request(id: 'a', amount: 3860, status: 'Requested'),
        _request(id: 'b', amount: 2400, status: 'Paid'),
        _request(id: 'c', amount: 1800, status: 'Rejected'),
        _request(id: 'd', amount: 900, status: 'Cancelled'),
      ];
      expect(outstandingPayoutTotal(requests), 3860);
      expect(liveRequest(requests)?.id, 'a');
    });

    test('two live requests both count as out', () {
      final requests = [
        _request(id: 'a', amount: 1000),
        _request(id: 'b', amount: 250),
      ];
      expect(outstandingPayoutTotal(requests), 1250);
    });

    test('nothing live means nothing out and no trail to draw', () {
      final requests = [_request(status: 'Paid'), _request(status: 'Rejected')];
      expect(outstandingPayoutTotal(requests), 0);
      expect(liveRequest(requests), isNull);
    });

    test('Rejected and Cancelled credit back; Paid does not', () {
      expect(_request(status: 'Rejected').isCreditedBack, isTrue);
      expect(_request(status: 'Cancelled').isCreditedBack, isTrue);
      expect(_request(status: 'Paid').isCreditedBack, isFalse);
      expect(_request(status: 'Requested').isCreditedBack, isFalse);
    });

    test('an unrecognised status is inert, never guessed into a state', () {
      final record = _request(status: 'Escheated');
      expect(record.status, PayoutStatus.unknown);
      expect(record.isLive, isFalse);
      expect(record.isCreditedBack, isFalse);
    });

    test('the snapshotted bank block parses off the nested map', () {
      final record = _request();
      expect(record.bankName, 'Thrift Union');
      expect(record.accountHolderName, 'Naledi Dlamini');
      expect(record.accountType, 'Savings');
    });

    test('a missing bank block does not throw', () {
      final record = PayoutRequestRecord.fromJson(const {
        'id': 'x',
        'amount': 10,
        'status': 'Paid',
      });
      expect(record.bankName, isNull);
      expect(record.accountNumber, isNull);
    });
  });

  group('account masking is manners, not protection', () {
    test('shows the last four behind bullets', () {
      expect(maskAccountNumber('9911002233'), '•••• 2233');
    });

    test('a short number is shown whole rather than invented around', () {
      expect(maskAccountNumber('771'), '771');
      expect(maskAccountNumber('7712'), '7712');
    });

    test('nothing in, nothing out', () {
      expect(maskAccountNumber(null), '');
      expect(maskAccountNumber('   '), '');
    });
  });

  group('the three date forms of frames 49f and 49k', () {
    final now = DateTime(2026, 8, 31, 18, 0);

    test('same day is today', () {
      expect(classifyDay(DateTime(2026, 8, 31, 16, 42), now),
          MovementDay.today);
    });

    test('the day before is yesterday', () {
      expect(classifyDay(DateTime(2026, 8, 30, 9, 12), now),
          MovementDay.yesterday);
    });

    test('anything older carries its own date', () {
      expect(classifyDay(DateTime(2026, 8, 28, 11, 40), now),
          MovementDay.earlier);
    });

    test('a clock skew into the future still reads as today', () {
      expect(classifyDay(DateTime(2026, 9, 1, 0, 5), now), MovementDay.today);
    });
  });
}
