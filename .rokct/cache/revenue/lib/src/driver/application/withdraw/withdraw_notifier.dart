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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imported directly (not via handlers.dart) because ApiResult's `when` is an
// EXTENSION declared in the generated `api_result.freezed.dart` part — it is
// only in scope for a library that imports its defining library, which is
// what the sibling statistics_notifier does too.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/infrastructure/wallet_balance_cache.dart';
import 'package:revenue_sdk/src/driver/application/withdraw/withdraw_state.dart';

/// The driver's withdraw call.
///
/// ERROR WORDING (Ray's standing rule, decision-log entry 56): a
/// driver-facing failure shows ONLY a friendly line. It never shows the
/// raw server message and never distinguishes one backend cause from
/// another — "no bank account on file", "insufficient balance" and a
/// provider outage all read the same on screen. The admin-grade detail
/// (verbatim server message + status code) rides the ONE telemetry door,
/// [ErrorPresenter.showTechnical] -> `TelemetryClient.logError` ->
/// backend `log_frontend_error`.
///
/// [ErrorPresenter.show] is deliberately NOT used here: it would echo a
/// definitive 4xx verbatim, and Frappe answers a `frappe.throw` with 417 —
/// inside that band — so the server's own wording would reach the driver.
/// The unconditional technical branch is the only one that honours the
/// rule on this surface.
class WithdrawNotifier extends StateNotifier<WithdrawState> {
  WithdrawNotifier(this._repository) : super(const WithdrawState());

  final DriverPayoutRepositoryFacade _repository;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'driver_payout_request';

  /// Requests a payout of [amount].
  ///
  /// The SERVER is the authority: it re-reads the balance under a Wallet
  /// row lock and refuses a non-positive amount, an over-balance amount
  /// and a driver with no bank account on file. On success the wallet has
  /// ALREADY been debited (the hold), so [onSuccess] receives the new
  /// balance the server reported and the caller can show it straight
  /// away — the money really is on its way.
  Future<void> requestPayout({
    required BuildContext context,
    required double amount,
    String? bankAccount,
    void Function(num? newBalance)? onSuccess,
  }) async {
    if (state.isSubmitting) return;

    if (!await AppConnectivity.connectivity()) {
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return;
    }

    state = state.copyWith(isSubmitting: true);
    final response = await _repository.requestPayout(
      amount: amount,
      bankAccount: bankAccount,
    );
    response.when(
      success: (data) {
        if (!data.success) {
          // A 200 that is not an acceptance. Nothing was held; treat it
          // exactly like a failure so no success copy can ever appear
          // over an unmoved wallet.
          state = state.copyWith(isSubmitting: false);
          if (context.mounted) {
            ErrorPresenter.showTechnical(
              context,
              type: errorType,
              detail: 'request_payout answered without success=true',
              extra: {'amount': '$amount'},
            );
          }
          return;
        }
        state = state.copyWith(
          isSubmitting: false,
          lastRequestId: data.requestId,
          lastAmount: data.amount,
          newBalance: data.newBalance,
        );
        _mirrorNewBalance(data.newBalance);
        if (context.mounted) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(TrKeys.moneySentSuccessfully),
          );
        }
        onSuccess?.call(data.newBalance);
      },
      failure: (failure, status) {
        state = state.copyWith(isSubmitting: false);
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            extra: {'amount': '$amount'},
          );
        }
      },
    );
  }

  /// Writes the server's post-hold balance onto the cached profile so the
  /// income and profile pages — both of which read
  /// `LocalStorage.getUser()?.wallet?.price` — show the money as gone the
  /// moment the request is accepted, which is what the server actually
  /// did. Best-effort: a storage failure must never turn an accepted
  /// payout into an on-screen error.
  Future<void> _mirrorNewBalance(num? newBalance) =>
      WalletBalanceCache.mirror(newBalance);
}
