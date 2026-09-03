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

// Gateway contract for the manager's deposit decisions (design strip
// frame 49i). They travel the universal platform gateway under wallet's
// own `api.wallet.*` aliases; these tests pin the cmds, the payload shape,
// and the typing of what comes back — including that the wire's `name`
// and `id` both resolve to the row id.

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/deposit_request_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/repositories/deposit_approval_repository.dart';

import 'support/recording_http_service.dart';

T _data<T>(ApiResult<T> result) => switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw StateError('unexpected failure: $error'),
    };

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  test('listPendingDepositRequests posts the cmd and types the queue',
      () async {
    final http = RecordingHttpService.install((_) => [
          {
            'id': 'WDR-1',
            'user': 'thabo@example.test',
            'user_name': 'Thabo Mokoena',
            'amount': 1240,
            'method': 'Bank Deposit',
            'reference': 'TM-0831-1642',
            'slip': 'https://files.test/slip.jpg',
            'status': 'Pending',
            'balance_at_submit': -1240.0,
            'submitted_at': '2026-08-31 16:42:00',
          },
        ]);

    final rows = _data(await DepositApprovalRepository().listPendingDepositRequests());

    final request = http.single;
    expect(request.method, 'POST');
    expect(request.path, kPlatformGatewayPath);
    expect(request.cmd, 'api.wallet.list_pending_deposit_requests');
    expect(rows, hasLength(1));
    expect(rows.single.id, 'WDR-1');
    expect(rows.single.displayName, 'Thabo Mokoena');
    expect(rows.single.status, DepositRequestStatus.pending);
    expect(rows.single.balanceAtSubmit, -1240.0);
    expect(rows.single.slipUrl, 'https://files.test/slip.jpg');
    expect(rows.single.submittedAt, DateTime(2026, 8, 31, 16, 42));
  });

  test('approveDepositRequest names the row and reads the credit', () async {
    final http = RecordingHttpService.install((_) => {
          'approved': true,
          'request_id': 'WDR-1',
          'amount': 1240.0,
          'new_balance': 0.0,
        });

    final resolution =
        _data(await DepositApprovalRepository().approveDepositRequest('WDR-1'));

    expect(http.single.cmd, 'api.wallet.approve_deposit_request');
    expect(http.single.payload, {'request_id': 'WDR-1'});
    expect(resolution.approved, isTrue);
    expect(resolution.amount, 1240.0);
    expect(resolution.newBalance, 0.0);
  });

  test('rejectDepositRequest carries the reason', () async {
    final http = RecordingHttpService.install((_) => {
          'rejected': true,
          'request_id': 'WDR-1',
          'reason': 'Bank received R 300.00.',
        });

    final resolution = _data(await DepositApprovalRepository()
        .rejectDepositRequest('WDR-1', reason: 'Bank received R 300.00.'));

    expect(http.single.cmd, 'api.wallet.reject_deposit_request');
    expect(http.single.payload, {
      'request_id': 'WDR-1',
      'reason': 'Bank received R 300.00.',
    });
    expect(resolution.approved, isFalse);
    expect(resolution.reason, 'Bank received R 300.00.');
  });

  test('a bare `name` still resolves to the id', () {
    final row = DepositRequestRecord.fromJson({'name': 'abc123', 'amount': '5'});
    expect(row.id, 'abc123');
    expect(row.amount, 5);
    expect(row.status, DepositRequestStatus.unknown);
  });
}
