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

// Design strip frames 49g/49h/49i — the wording and arithmetic rules of
// the deposit screens, with no widgets in the way. What a later edit could
// quietly undo: the balance is a SENTENCE (never "−1240"); the reference
// is generated FOR the driver in the shape the server generates; a status
// has exactly one colour.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_grammar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the balance is a sentence', () {
    test('negative reads as owing, zero as clear, positive as available', () {
      expect(toneFor(-1240), BalanceTone.owing);
      expect(toneFor(0), BalanceTone.empty);
      expect(toneFor(350.5), BalanceTone.available);
    });

    test('each tone leads with its own line', () {
      expect(balanceLeadKey(BalanceTone.owing), 'you_owe');
      expect(balanceLeadKey(BalanceTone.empty), 'your_wallet_is_clear');
      expect(balanceLeadKey(BalanceTone.available), 'you_have');
    });
  });

  group('chip 977 - the suggested reference', () {
    final when = DateTime(2026, 8, 31, 16, 42);

    test('initials, day and minute in the shape the server generates', () {
      expect(suggestedReference('Thabo Mokoena', when), 'TM-0831-1642');
      expect(
        suggestedReference('Thabo Mokoena', when),
        matches(RegExp(r'^[A-Z]{1,3}-\d{4}-\d{4}$')),
      );
    });

    test('caps the initials at three and drops non-letters', () {
      expect(
        suggestedReference("Anna-Marie O'Neil van der Berg", when),
        'AOV-0831-1642',
      );
    });

    test('a driver with no name still gets a reference', () {
      expect(suggestedReference(null, when), 'DEP-0831-1642');
      expect(suggestedReference('   ', when), 'DEP-0831-1642');
    });
  });

  group('status chips', () {
    test('under review is amber, approved green, rejected red', () {
      expect(depositStatusView(DepositStatus.pending).labelKey, 'under_review');
      expect(depositStatusView(DepositStatus.pending).color, AppStyle.rate);
      expect(depositStatusView(DepositStatus.approved).color, AppStyle.green);
      expect(depositStatusView(DepositStatus.rejected).color, AppStyle.red);
    });

    test('the wire spellings parse, anything else is unknown', () {
      expect(DepositStatus.parse('Pending'), DepositStatus.pending);
      expect(DepositStatus.parse('approved'), DepositStatus.approved);
      expect(DepositStatus.parse('Rejected'), DepositStatus.rejected);
      expect(DepositStatus.parse('Draft'), DepositStatus.draft);
      expect(DepositStatus.parse('whatever'), DepositStatus.unknown);
      expect(DepositStatus.parse(null), DepositStatus.unknown);
    });

    test('only pending is live', () {
      expect(DepositStatus.pending.isLive, isTrue);
      expect(DepositStatus.approved.isLive, isFalse);
      expect(DepositStatus.rejected.isLive, isFalse);
    });
  });

  group('how a row dates itself', () {
    final now = DateTime(2026, 9, 3, 10, 0);

    test('today, yesterday, earlier', () {
      expect(classifyDay(DateTime(2026, 9, 3, 1), now), DepositDay.today);
      expect(classifyDay(DateTime(2026, 9, 2, 23, 59), now), DepositDay.yesterday);
      expect(classifyDay(DateTime(2026, 8, 31), now), DepositDay.earlier);
    });

    test('describeWhen keeps the minute and names the day', () {
      expect(describeWhen(DateTime(2026, 9, 3, 16, 42), now), 'Today 16:42');
      expect(describeWhen(DateTime(2026, 9, 2, 8, 5), now), 'Yesterday 08:05');
      expect(describeWhen(DateTime(2026, 8, 31, 16, 42), now), '31 Aug 16:42');
      expect(describeWhen(DateTime(2025, 12, 1, 9, 0), now), '1 Dec 2025 09:00');
    });
  });

  group('the destination', () {
    test('masks the account on screen', () {
      const d = DepositDestination(accepting: true, accountNumber: '0000004417');
      expect(d.maskedAccountNumber, isNot(contains('0000004417')));
      expect(d.maskedAccountNumber, endsWith('4417'));
    });
  });
}
