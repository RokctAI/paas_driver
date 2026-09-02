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

import 'package:base_sdk/base_sdk.dart';

import '../../domain/interface/loyalty_repository_facade.dart';
import '../../domain/models/loyalty_models.dart';

/// Offline default over base_sdk's shared database. Balances live in the
/// 'loyalty_accounts' box, the ledger in 'loyalty_transactions'.
class LocalLoyaltyRepository implements LoyaltyRepositoryFacade {
  static const String _accounts = 'loyalty_accounts';
  static const String _transactions = 'loyalty_transactions';

  @override
  Future<ApiResult<LoyaltyAccount>> getAccount({
    required String ownerId,
    String program = 'default',
  }) async {
    try {
      final id = '$program:$ownerId';
      final row = await AppDatabase().getItem(_accounts, id);
      final account = row != null
          ? LoyaltyAccount.fromJson(row)
          : LoyaltyAccount(
              accountId: id,
              ownerId: ownerId,
              program: program,
              balance: 0,
              updatedAt: DateTime.now(),
            );
      return ApiResult.success(data: account);
    } catch (e) {
      return ApiResult.failure(error: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ApiResult<List<LoyaltyTransaction>>> getTransactions(
    String accountId,
  ) async {
    try {
      final rows = await AppDatabase().getAll(_transactions);
      final list = rows
          .map(LoyaltyTransaction.fromJson)
          .where((t) => t.accountId == accountId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ApiResult.success(data: list);
    } catch (e) {
      return ApiResult.failure(error: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ApiResult<LoyaltyAccount>> record(
    LoyaltyTransaction transaction,
  ) async {
    try {
      final db = AppDatabase();
      final row = await db.getItem(_accounts, transaction.accountId);
      if (row == null) {
        return const ApiResult.failure(
          error: 'Unknown loyalty account',
          statusCode: 404,
        );
      }
      final account = LoyaltyAccount.fromJson(row);
      final delta = switch (transaction.type) {
        LoyaltyTransactionType.earn => transaction.points,
        LoyaltyTransactionType.adjust => transaction.points,
        LoyaltyTransactionType.redeem => -transaction.points,
        LoyaltyTransactionType.expire => -transaction.points,
      };
      final newBalance = account.balance + delta;
      if (newBalance < 0) {
        return const ApiResult.failure(
          error: 'Insufficient loyalty balance',
          statusCode: 422,
        );
      }
      final updated =
          account.copyWith(balance: newBalance, updatedAt: DateTime.now());
      await db.putItem(
        _transactions,
        transaction.transactionId,
        transaction.toJson(),
      );
      await db.putItem(_accounts, updated.accountId, updated.toJson());
      return ApiResult.success(data: updated);
    } catch (e) {
      return ApiResult.failure(error: e.toString(), statusCode: 500);
    }
  }
}
