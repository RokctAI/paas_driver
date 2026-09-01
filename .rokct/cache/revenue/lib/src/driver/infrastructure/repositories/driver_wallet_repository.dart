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

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/domain/interface/driver_wallet.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/wallet_movement.dart';

/// The wallet plane's two reads, on defs this SDK does not own.
///
/// Same shape as [CourierStatisticsRepository] and
/// [DriverPayoutRepository]: a prefix-free `cmd` (the target app's
/// `manifest.json` whitelisted-method key with the app segment dropped)
/// through base_sdk's universal platform gateway, whose path is already the
/// versioned `/api/v1/method/...` form. paas_driver composes neither
/// wallet_sdk nor a users SDK, so there is nothing to import — the gateway
/// resolves the name against the composed app's own whitelist server-side.
class DriverWalletRepository implements DriverWalletRepositoryFacade {
  /// wallet's `{app_name}.api.payment.*` keys, app segment dropped. The
  /// balance def documents this exact cmd on itself
  /// (pay `wallet/frappe/src/tenant/api/payment/payment.py:1542-1560`).
  static const _paymentCmd = 'api.payment';

  /// users' `{app_name}.api.user.*` keys, app segment dropped
  /// (Users `users/frappe/src/tenant/api/user/user.py:1297-1320`).
  static const _userCmd = 'api.user';

  static const _gateway = PlatformGateway();

  Map<String, dynamic> _asMap(dynamic response) => response is Map
      ? Map<String, dynamic>.from(response)
      : <String, dynamic>{};

  @override
  Future<ApiResult<num>> getBalance() async {
    try {
      // `get_wallet_balance()` answers {balance, currency}. It is a pure
      // read: a driver with no Wallet row reads zero and no row is
      // created. The value may be NEGATIVE and that is correct.
      final response = await _gateway.tenant('$_paymentCmd.get_wallet_balance');
      final map = _asMap(response);
      final raw = map['balance'];
      final balance =
          raw is num ? raw : num.tryParse('${raw ?? ''}');
      if (balance == null) {
        // A 200 that carries no balance is not an answer. Failing here
        // keeps the plane on its last known figure instead of silently
        // drawing zero over a real debt.
        return ApiResult.failure(
          error: 'get_wallet_balance answered without a numeric balance',
          statusCode: 200,
        );
      }
      return ApiResult.success(data: balance);
    } catch (e) {
      debugPrint('===> get wallet balance error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<List<WalletMovement>>> getMovements({
    int start = 0,
    int limit = 20,
  }) async {
    try {
      // `get_wallet_history(start, limit)` answers the shared
      // `api_response` envelope — {"data": [...], "status_code": 200} —
      // so the rows are under `data`, unlike `list_payout_requests`
      // which answers a bare list.
      final response = await _gateway.tenant(
        '$_userCmd.get_wallet_history',
        {'start': start, 'limit': limit},
      );
      return ApiResult.success(
        data: WalletMovement.listFrom(_asMap(response)['data']),
      );
    } catch (e) {
      debugPrint('===> get wallet history error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
