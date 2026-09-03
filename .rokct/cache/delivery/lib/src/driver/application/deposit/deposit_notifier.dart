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
// only in scope for a library that imports its defining library.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';

import 'package:delivery_sdk/src/driver/application/deposit/deposit_state.dart';
import 'package:delivery_sdk/src/driver/domain/interface/deposit.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';

/// Radio-level connectivity gate, injectable so the sheets' tests can run
/// the whole flow against a fake repository without a platform channel.
typedef ConnectivityCheck = Future<bool> Function();

/// The driver's deposit flow (design strip frames 49g/49h/49i).
///
/// ERROR WORDING (Ray's standing rule): a driver facing failure sees ONE
/// friendly line, never the server's sentence; the verbatim detail rides
/// [ErrorPresenter.showTechnical] to telemetry. Frappe answers a
/// `frappe.throw` with 417, inside [ErrorPresenter.show]'s definitive-4xx
/// band, which is why `show` is deliberately not used here.
class DepositNotifier extends StateNotifier<DepositState> {
  DepositNotifier(this._repository, {ConnectivityCheck? isOnline})
      : _isOnline = isOnline ?? AppConnectivity.connectivity,
        super(const DepositState());

  final DriverDepositRepositoryFacade _repository;
  final ConnectivityCheck _isOnline;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'driver_deposit';

  /// Chip 975: read BEFORE the capture sheet opens, so a tenant that is not
  /// accepting bank deposits meets the fact instead of a form.
  Future<void> loadDestination({BuildContext? context}) async {
    if (state.isLoadingDestination) return;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    state = state.copyWith(isLoadingDestination: true, destinationFailed: false);
    final response = await _repository.getDestination();
    response.when(
      success: (destination) {
        state = state.copyWith(
          destination: destination,
          isLoadingDestination: false,
        );
      },
      failure: (failure, status) {
        state = state.copyWith(
          isLoadingDestination: false,
          destinationFailed: true,
        );
        if (context != null && context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            friendly: AppHelpers.getTranslation(
              'we_couldnt_load_the_bank_details_try_again_in_a_moment',
            ),
            extra: const {'op': 'get_deposit_destination'},
          );
        }
      },
    );
  }

  /// Chip 971's figure and chip 982's rows, together — the status plane's
  /// two reads. Failures are stated on the plane itself, never as a toast.
  Future<void> load({BuildContext? context}) async {
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    state = state.copyWith(
      isLoadingDeposits: true,
      depositsFailed: false,
      balanceFailed: false,
    );
    final results = await Future.wait([
      _repository.getWalletBalance(),
      _repository.listMyDeposits(),
    ]);
    final balance = results[0] as ApiResult<num>;
    final deposits = results[1] as ApiResult<List<DepositRecord>>;
    balance.when(
      success: (value) => state = state.copyWith(balance: value),
      failure: (_, __) => state = state.copyWith(balanceFailed: true),
    );
    deposits.when(
      success: (rows) => state = state.copyWith(
        deposits: rows,
        isLoadingDeposits: false,
        depositsLoadedOnce: true,
      ),
      failure: (_, __) => state = state.copyWith(
        isLoadingDeposits: false,
        depositsFailed: true,
        depositsLoadedOnce: true,
      ),
    );
  }

  /// Chip 978 — Send for approval.
  ///
  /// The SERVER is the authority: it refuses a non-positive amount, a
  /// missing slip, a duplicate reference and a tenant that is not
  /// accepting deposits. On success NOTHING has moved: [onSuccess] receives
  /// the row as the history will show it, and the balance the server
  /// reported is stored unchanged — it is still the debt.
  Future<void> submit({
    required BuildContext context,
    required double amount,
    required String slipPath,
    String? reference,
    void Function(DepositRecord sent)? onSuccess,
  }) async {
    if (state.isSubmitting) return;
    // Claimed BEFORE the first await, so two taps in the same frame cannot
    // both pass the guard and send two requests.
    state = state.copyWith(isSubmitting: true);

    if (!await _isOnline()) {
      state = state.copyWith(isSubmitting: false);
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return;
    }

    final response = await _repository.submitDeposit(
      amount: amount,
      slipPath: slipPath,
      reference: reference,
    );
    response.when(
      success: (data) {
        if (!data.success) {
          state = state.copyWith(isSubmitting: false);
          if (context.mounted) {
            ErrorPresenter.showTechnical(
              context,
              type: errorType,
              detail: 'submit_deposit_request answered without success=true',
              extra: {'amount': '$amount'},
            );
          }
          return;
        }
        final sent = data.toRecord();
        state = state.copyWith(
          isSubmitting: false,
          lastSubmitted: sent,
          deposits: [sent, ...state.deposits.where((r) => r.id != sent.id)],
          // The wire says what the wallet reads now; it has NOT changed.
          balance: data.balance ?? state.balance,
        );
        onSuccess?.call(sent);
      },
      failure: (failure, status) {
        state = state.copyWith(isSubmitting: false);
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            friendly: AppHelpers.getTranslation(
              'we_couldnt_send_your_deposit_nothing_has_changed_try_again',
            ),
            extra: {'op': 'submit_deposit_request', 'amount': '$amount'},
          );
        }
      },
    );
  }
}
