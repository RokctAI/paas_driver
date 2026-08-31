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

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_response.dart';

/// The driver's withdraw call, on wallet's payout def.
///
/// Same shape as [CourierStatisticsRepository]: a prefix-free `cmd` base
/// (wallet `manifest.json`'s whitelisted-method keys
/// `{app_name}.api.payout.*` with the app segment dropped) through
/// base_sdk's universal platform gateway. paas_driver composes no
/// wallet_sdk, so there is nothing to import — the gateway resolves the
/// name against the composed app's own whitelist server-side.
class DriverPayoutRepository implements DriverPayoutRepositoryFacade {
  /// Prefix-free cmd base for the universal platform gateway: wallet's
  /// `manifest.json` whitelisted-method keys (`{app_name}.api.payout.*`)
  /// with the app segment dropped.
  static const _payoutCmd = 'api.payout';

  static const _gateway = PlatformGateway();

  Map<String, dynamic> _asMap(dynamic response) => response is Map
      ? Map<String, dynamic>.from(response)
      : <String, dynamic>{};

  @override
  Future<ApiResult<PayoutRequestResponse>> requestPayout({
    required double amount,
    String? bankAccount,
  }) async {
    try {
      // `request_payout(amount, bank_account=None)`. The server validates
      // the amount strictly positive and finite, re-reads the balance
      // under a Wallet row lock, and refuses a driver with no bank
      // account on file. On success it has ALREADY debited the wallet
      // and answers {success, request_id, amount, new_balance}.
      final data = <String, dynamic>{
        'amount': amount,
        if (bankAccount != null && bankAccount.isNotEmpty)
          'bank_account': bankAccount,
      };
      final response = await _gateway.tenant(
        '$_payoutCmd.request_payout',
        data,
      );
      return ApiResult.success(
        data: PayoutRequestResponse.fromJson(_asMap(response)),
      );
    } catch (e) {
      debugPrint('===> request payout error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<List<PayoutRequestRecord>>> listPayoutRequests() async {
    try {
      // `list_payout_requests()` takes no arguments and answers a BARE
      // list (not a `{"data": ...}` envelope), newest first, capped at
      // 100 rows server-side.
      final response = await _gateway.tenant('$_payoutCmd.list_payout_requests');
      return ApiResult.success(
        data: PayoutRequestRecord.listFrom(response),
      );
    } catch (e) {
      debugPrint('===> list payout requests error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<List<BankAccountRecord>>> listBankAccounts() async {
    try {
      // `list_bank_accounts()` takes no arguments and answers a BARE list
      // (not a `{"data": ...}` envelope) of `_account_payload` maps, the
      // default account first then newest.
      final response = await _gateway.tenant('$_payoutCmd.list_bank_accounts');
      return ApiResult.success(data: BankAccountRecord.listFrom(response));
    } catch (e) {
      debugPrint('===> list bank accounts error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<BankAccountRecord>> addBankAccount({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    String? branchCode,
    String? accountType,
    bool isDefault = false,
  }) async {
    try {
      // `add_bank_account(account_holder_name, bank_name, account_number,
      // branch_code=None, account_type=None, is_default=0)` — the endpoint's
      // own argument order, which is also the order frame 49o draws.
      //
      // The optional pair is sent only when it carries something: the
      // endpoint's `_optional_text` treats null and empty identically, and
      // omitting them keeps the wire honest about what the driver chose.
      // `is_default` rides as Frappe's Check integer, not as a JSON bool.
      final trimmedBranch = (branchCode ?? '').trim();
      final trimmedType = (accountType ?? '').trim();
      final data = <String, dynamic>{
        'account_holder_name': accountHolderName.trim(),
        'bank_name': bankName.trim(),
        'account_number': accountNumber.trim(),
        if (trimmedBranch.isNotEmpty) 'branch_code': trimmedBranch,
        if (trimmedType.isNotEmpty) 'account_type': trimmedType,
        'is_default': isDefault ? 1 : 0,
      };
      final response = await _gateway.tenant(
        '$_payoutCmd.add_bank_account',
        data,
      );
      // The def answers only {id, is_default} — it does not echo the fields
      // back — so the record is rebuilt from what was sent plus the two the
      // server decided. `is_default` in particular must come from the
      // ANSWER, never from the request: the first account a driver adds is
      // his default whatever the switch said (`payout.py:205-207`).
      final answer = _asMap(response);
      return ApiResult.success(
        data: BankAccountRecord(
          id: answer['id']?.toString() ?? '',
          accountHolderName: accountHolderName.trim(),
          bankName: bankName.trim(),
          accountNumber: accountNumber.trim(),
          branchCode: trimmedBranch.isEmpty ? null : trimmedBranch,
          accountType: trimmedType.isEmpty ? null : trimmedType,
          isDefault: BankAccountRecord.isTruthyFlag(answer['is_default']),
        ),
      );
    } catch (e) {
      debugPrint('===> add bank account error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<bool>> removeBankAccount(String bankAccount) async {
    try {
      // `remove_bank_account(bank_account)`. Refused while a still
      // `Requested` payout names the account (`payout.py:270-286`); the
      // screen predicts that refusal from the trail it already holds, so
      // this call is not how the driver normally learns of it.
      final response = await _gateway.tenant(
        '$_payoutCmd.remove_bank_account',
        <String, dynamic>{'bank_account': bankAccount},
      );
      final answer = _asMap(response);
      return ApiResult.success(
        data: BankAccountRecord.isTruthyFlag(answer['removed']),
      );
    } catch (e) {
      debugPrint('===> remove bank account error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<bool>> setDefaultBankAccount(String bankAccount) async {
    try {
      // `set_default_bank_account(bank_account)`.
      //
      // NOTE, and it is the one thing on this surface that is not already
      // shipped: `payout.py` exposed add / list / remove only, so moving the
      // default mark onto an existing account had no endpoint. It is added
      // alongside the others in the pay repo. Everything else this screen
      // does works against the backend exactly as it stands.
      //
      // The withdraw path deliberately does NOT depend on this call: it
      // names the account explicitly on `request_payout`, so a driver on a
      // backend that predates the endpoint can still withdraw from any of
      // his accounts. Only the default MARK is unreachable there, and the
      // failure reads as one friendly line like any other.
      final response = await _gateway.tenant(
        '$_payoutCmd.set_default_bank_account',
        <String, dynamic>{'bank_account': bankAccount},
      );
      final answer = _asMap(response);
      return ApiResult.success(
        data: BankAccountRecord.isTruthyFlag(answer['is_default']),
      );
    } catch (e) {
      debugPrint('===> set default bank account error $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
