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

// A double tap on Withdraw must request ONE payout. The server debits the
// wallet on every accepted request, so a second call is a second debit.
// The guard flag was claimed after the connectivity round trip, so two taps
// inside that round trip both got through.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:revenue_sdk/src/common/application/withdraw/withdraw_notifier.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_response.dart';

class _CountingRepo implements DriverPayoutRepositoryFacade {
  int payouts = 0;

  @override
  Future<ApiResult<PayoutRequestResponse>> requestPayout({
    required double amount,
    String? bankAccount,
  }) async {
    payouts++;
    return const ApiResult.success(
      data: PayoutRequestResponse(success: true, newBalance: 0),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('two taps inside the connectivity check request one payout',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));

    final repo = _CountingRepo();
    final gate = Completer<bool>();
    final notifier = WithdrawNotifier(repo, isOnline: () => gate.future);

    final first = notifier.requestPayout(context: context, amount: 100);
    final second = notifier.requestPayout(context: context, amount: 100);
    gate.complete(true);
    await first;
    await second;

    expect(repo.payouts, 1);
    notifier.dispose();
  });

  testWidgets('offline releases the guard so the driver can try again',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));
    // Unmount it: the offline branch then skips its snackbar, which needs a
    // fully themed app this test does not build. The guard is what matters.
    await tester.pumpWidget(const SizedBox());

    final repo = _CountingRepo();
    bool online = false;
    final notifier = WithdrawNotifier(repo, isOnline: () async => online);

    await notifier.requestPayout(context: context, amount: 100);
    expect(notifier.state.isSubmitting, isFalse);
    expect(repo.payouts, 0);

    online = true;
    await notifier.requestPayout(context: context, amount: 100);
    expect(repo.payouts, 1);
    notifier.dispose();
  });
}
