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
import 'package:base_sdk/src/services/enums.dart';

import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/domain/interface/deposit.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';

/// The driver's deposit calls, on wallet's `api.wallet.*` defs.
///
/// Same shape as [CourierRepository]: a prefix-free `cmd` base (wallet
/// `manifest.json`'s whitelisted-method keys `{app_name}.api.wallet.*` with
/// the app segment dropped) through base_sdk's universal platform gateway.
/// The slip is the ONE exception the gateway rule allows — file bytes
/// cannot ride the JSON envelope — so it goes up through the multipart
/// gallery seam ([galleryRepository], products_sdk's implementation of
/// base's facade, registered in every driver compose) exactly as the
/// courier's profile photo and vehicle photo do, and only its URL rides
/// the deposit call.
class DriverDepositRepository implements DriverDepositRepositoryFacade {
  static const _walletCmd = 'api.wallet';
  static const _paymentCmd = 'api.payment';
  static const _gateway = PlatformGateway();

  Map<String, dynamic> _asMap(dynamic response) => response is Map
      ? Map<String, dynamic>.from(response)
      : <String, dynamic>{};

  @override
  Future<ApiResult<DepositDestination>> getDestination() async {
    try {
      final response =
          await _gateway.tenant('$_walletCmd.get_deposit_destination');
      return ApiResult.success(data: DepositDestination.fromJson(response));
    } catch (e) {
      debugPrint('===> get deposit destination error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<num>> getWalletBalance() async {
    try {
      // `get_wallet_balance()` answers {balance, currency} from the
      // canonical Wallet ledger; a user with no row reads as zero.
      final response = await _gateway.tenant('$_paymentCmd.get_wallet_balance');
      final raw = _asMap(response)['balance'];
      final num balance =
          raw is num ? raw : num.tryParse('${raw ?? ''}') ?? 0;
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
  Future<ApiResult<DepositSubmitResponse>> submitDeposit({
    required double amount,
    required String slipPath,
    String method = DepositMethod.bankDeposit,
    String? reference,
    String? note,
  }) async {
    // Multipart first. UploadType.users is what the courier's own uploads
    // already resolve to on the Frappe gallery (see
    // profile_image_notifier.dart); the enum has no closer member and
    // adding one would break products_sdk's exhaustive switch.
    final upload = await galleryRepository.uploadImage(slipPath, UploadType.users);
    final String? slipUrl = switch (upload) {
      Success(:final data) => data.imageData?.title,
      Failure() => null,
    };
    if (upload is Failure<dynamic>) {
      final failure = upload as Failure;
      return ApiResult.failure(
        error: failure.error,
        statusCode: failure.statusCode,
      );
    }
    if (slipUrl == null || slipUrl.trim().isEmpty) {
      return const ApiResult.failure(
        error: 'The slip photo did not upload.',
        statusCode: 500,
      );
    }
    try {
      // `submit_deposit_request(amount, method, reference=None, slip=None,
      // note=None)`. Nothing moves in the wallet on this call.
      final trimmedReference = (reference ?? '').trim();
      final trimmedNote = (note ?? '').trim();
      final response =
          await _gateway.tenant('$_walletCmd.submit_deposit_request', {
        'amount': amount,
        'method': method,
        'slip': slipUrl,
        if (trimmedReference.isNotEmpty) 'reference': trimmedReference,
        if (trimmedNote.isNotEmpty) 'note': trimmedNote,
      });
      return ApiResult.success(
        data: DepositSubmitResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('===> submit deposit error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<List<DepositRecord>>> listMyDeposits() async {
    try {
      // Bare list, newest first, capped at 100 server-side.
      final response = await _gateway.tenant('$_walletCmd.list_deposit_requests');
      return ApiResult.success(data: DepositRecord.listFrom(response));
    } catch (e) {
      debugPrint('===> list deposits error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
