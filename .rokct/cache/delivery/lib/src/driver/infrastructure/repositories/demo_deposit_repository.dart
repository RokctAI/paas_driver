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

import 'package:base_sdk/src/handlers/handlers.dart';

import 'package:delivery_sdk/src/driver/domain/interface/deposit.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';

/// Demo twin of [DriverDepositRepository] (`--dart-define=IS_DEMO=true`),
/// the same isDemo split every other courier facade has. Serves a driver
/// who owes money, one deposit under review, one approved and one rejected
/// with its reason — frame 49i's three outcomes — and accepts a submission
/// offline without moving the balance, which is the real behaviour too.
class DemoDriverDepositRepository implements DriverDepositRepositoryFacade {
  DemoDriverDepositRepository({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  num _balance = -1240;
  final List<DepositRecord> _rows = [];
  int _counter = 0;

  List<DepositRecord> _seed() {
    final now = _now();
    return [
      DepositRecord(
        id: 'DEMO-DEP-2',
        amount: 900,
        status: DepositStatus.approved,
        method: DepositMethod.bankDeposit,
        reference: 'TM-0830-0847',
        submittedAt: now.subtract(const Duration(days: 1)),
        resolvedAt: now.subtract(const Duration(hours: 20)),
        credited: true,
      ),
      DepositRecord(
        id: 'DEMO-DEP-1',
        amount: 600,
        status: DepositStatus.rejected,
        method: DepositMethod.bankDeposit,
        reference: 'TM-0829-0812',
        rejectionReason: 'Slip says R 600.00, the bank received R 300.00.',
        submittedAt: now.subtract(const Duration(days: 2)),
        resolvedAt: now.subtract(const Duration(days: 2, hours: -2)),
      ),
    ];
  }

  @override
  Future<ApiResult<DepositDestination>> getDestination() async =>
      const ApiResult.success(
        data: DepositDestination(
          accepting: true,
          accountHolderName: 'Rokct Operations',
          bankName: 'Standard Bank',
          accountNumber: '0000004417',
          branchCode: '000000',
          accountType: 'Cheque',
          instructions: 'Write your reference on the slip.',
        ),
      );

  @override
  Future<ApiResult<num>> getWalletBalance() async =>
      ApiResult.success(data: _balance);

  @override
  Future<ApiResult<DepositSubmitResponse>> submitDeposit({
    required double amount,
    required String slipPath,
    String method = DepositMethod.bankDeposit,
    String? reference,
    String? note,
  }) async {
    _counter++;
    final now = _now();
    final ref = (reference ?? '').trim().isEmpty
        ? 'TM-${now.month.toString().padLeft(2, '0')}'
            '${now.day.toString().padLeft(2, '0')}-'
            '${now.hour.toString().padLeft(2, '0')}'
            '${now.minute.toString().padLeft(2, '0')}'
        : reference!.trim();
    final response = DepositSubmitResponse(
      success: true,
      requestId: 'DEMO-DEP-NEW-$_counter',
      reference: ref,
      amount: amount,
      submittedAt: now,
      // Nothing moves: the balance on the wire is still the debt.
      balance: _balance,
    );
    _rows.insert(0, response.toRecord(method: method));
    return ApiResult.success(data: response);
  }

  @override
  Future<ApiResult<List<DepositRecord>>> listMyDeposits() async =>
      ApiResult.success(data: [..._rows, ..._seed()]);
}
