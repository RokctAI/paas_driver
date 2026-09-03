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

import 'package:revenue_sdk/src/common/domain/interface/deposit_approval.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/deposit_request_record.dart';

/// The manager's deposit decisions, on wallet's `api.wallet.*` defs.
///
/// Same shape as [DriverPayoutRepository]: a prefix-free `cmd` base
/// (wallet `manifest.json`'s whitelisted-method keys `{app_name}.api.wallet.*`
/// with the app segment dropped) through base_sdk's universal platform
/// gateway. paas_manager composes no wallet_sdk, so there is nothing to
/// import — the gateway resolves the name against the composed app's own
/// whitelist server-side.
class DepositApprovalRepository implements DepositApprovalRepositoryFacade {
  static const _walletCmd = 'api.wallet';
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<List<DepositRequestRecord>>>
      listPendingDepositRequests() async {
    try {
      // Bare list, oldest first (a queue), capped server-side.
      final response =
          await _gateway.tenant('$_walletCmd.list_pending_deposit_requests');
      return ApiResult.success(data: DepositRequestRecord.listFrom(response));
    } catch (e) {
      debugPrint('===> list pending deposit requests error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<DepositResolution>> approveDepositRequest(
    String requestId,
  ) async {
    try {
      // `approve_deposit_request(request_id)` — the credit happens HERE,
      // once, and the answer carries the driver's new balance.
      final response = await _gateway.tenant(
        '$_walletCmd.approve_deposit_request',
        {'request_id': requestId},
      );
      return ApiResult.success(data: DepositResolution.fromJson(response));
    } catch (e) {
      debugPrint('===> approve deposit request error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<DepositResolution>> rejectDepositRequest(
    String requestId, {
    required String reason,
  }) async {
    try {
      // `reject_deposit_request(request_id, reason)` — the server refuses
      // an empty reason; the sheet never lets one through either.
      final response = await _gateway.tenant(
        '$_walletCmd.reject_deposit_request',
        {'request_id': requestId, 'reason': reason},
      );
      return ApiResult.success(data: DepositResolution.fromJson(response));
    } catch (e) {
      debugPrint('===> reject deposit request error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
