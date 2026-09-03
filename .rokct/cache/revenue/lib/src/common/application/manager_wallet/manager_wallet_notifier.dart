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
// what the sibling withdraw_notifier does too.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:revenue_sdk/src/common/application/manager_wallet/manager_wallet_scope.dart';
import 'package:revenue_sdk/src/common/application/manager_wallet/manager_wallet_state.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/wallet_balance_cache.dart';
import 'package:revenue_sdk/src/common/presentation/bank/bank_grammar.dart';

/// Radio-level connectivity gate, injectable so the pane's tests can run
/// the whole withdraw path against a fake repository without a platform
/// channel. Defaults to [AppConnectivity.connectivity].
typedef ConnectivityCheck = Future<bool> Function();

/// The manager's withdraw call (design strip frame 49l): the same request
/// the driver makes on 49j, on the same endpoint, from a different actor.
///
/// One slice per [scope] so a host that shows more than one shop keeps
/// their panes apart. The repository it delegates to is the ONE payout
/// seam this SDK has, [DriverPayoutRepositoryFacade] — the name is the
/// driver's because he got there first, but `api.payout.*` is USER-scoped
/// and serves any signed-in user; the manager app registers the same
/// concrete repository through `ManagerRevenueDependencies`.
///
/// ERROR WORDING (Ray's standing rule, decision-log entry 56): a person
/// facing failure sees ONE friendly line, never the server's sentence; the
/// verbatim detail rides [ErrorPresenter.showTechnical] to telemetry with
/// the shop in `extra`. [ErrorPresenter.show] is deliberately not used —
/// Frappe answers a `frappe.throw` with 417, inside `show`'s definitive-4xx
/// band, so the server's own wording would reach the screen.
class ManagerWalletNotifier extends StateNotifier<ManagerWalletState> {
  ManagerWalletNotifier(
    this._repository, {
    required this.scope,
    ConnectivityCheck? isOnline,
  })  : _isOnline = isOnline ?? AppConnectivity.connectivity,
        super(const ManagerWalletState());

  final DriverPayoutRepositoryFacade _repository;
  final ManagerWalletScope scope;
  final ConnectivityCheck _isOnline;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'manager_payout_request';

  Map<String, String> get _scopeExtra => {'shop': scope.shopId};

  /// Reads the accounts BEFORE anything opens — the order frame 49n insists
  /// on. `request_payout` refuses a caller with no `Payout Bank Account`
  /// row (`payout.py:137-157, 324-328`); asking `list_bank_accounts` first
  /// means no request is ever fired blind and nothing is held.
  ///
  /// [context] is optional so a host can pre-read silently.
  Future<void> loadAccounts({BuildContext? context}) async {
    if (state.isLoadingAccounts) return;
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    state = state.copyWith(isLoadingAccounts: true, accountsFailed: false);
    final response = await _repository.listBankAccounts();
    response.when(
      success: (accounts) {
        final keep = state.selectedAccountId != null &&
            accounts.any((account) => account.id == state.selectedAccountId);
        final String? selected = keep
            ? state.selectedAccountId
            : (defaultAccount(accounts) ??
                    (accounts.isEmpty ? null : accounts.first))
                ?.id;
        state = state.copyWith(
          accounts: accounts,
          isLoadingAccounts: false,
          accountsLoadedOnce: true,
          selectedAccountId: selected,
          clearSelectedAccountId: selected == null,
        );
      },
      failure: (failure, status) {
        state = state.copyWith(
          isLoadingAccounts: false,
          accountsFailed: true,
          accountsLoadedOnce: true,
        );
        if (context != null && context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            friendly: AppHelpers.getTranslation(
              'we_couldnt_load_your_bank_accounts_try_again_in_a_moment',
            ),
            extra: {'op': 'list_bank_accounts', ..._scopeExtra},
          );
        }
      },
    );
  }

  /// The manager's own tap in the sheet's bank block.
  void selectAccount(String id) =>
      state = state.copyWith(selectedAccountId: id);

  /// An account the bank-account form (frame 49o) just saved: carried
  /// straight into the list and named, so the manager goes on to the
  /// withdrawal rather than back to the button he already pressed.
  void adoptAccount(BankAccountRecord account) {
    final others =
        state.accounts.where((row) => row.id != account.id).toList();
    state = state.copyWith(
      accounts: [account, ...others],
      accountsLoadedOnce: true,
      accountsFailed: false,
      selectedAccountId: account.id,
    );
  }

  /// Requests a payout of [amount] to the selected account.
  ///
  /// The SERVER is the authority: it re-reads the balance under a Wallet
  /// row lock and refuses a non-positive amount, an over-balance amount and
  /// a caller with no bank account on file. On success the wallet has
  /// ALREADY been debited (the hold, `payout.py:345`), so [onSuccess]
  /// receives the balance the server reported and the pane draws it at
  /// once — the money really is on its way.
  Future<void> requestPayout({
    required BuildContext context,
    required double amount,
    void Function(num? newBalance)? onSuccess,
  }) async {
    if (state.isSubmitting) return;
    // Claimed BEFORE the first await, so two taps in the same frame cannot
    // both pass the guard and fire two holds.
    state = state.copyWith(isSubmitting: true);

    if (!await _isOnline()) {
      state = state.copyWith(isSubmitting: false);
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return;
    }

    final response = await _repository.requestPayout(
      amount: amount,
      bankAccount: state.selectedAccountId,
    );
    response.when(
      success: (data) {
        if (!data.success) {
          // A 200 that is not an acceptance. Nothing was held; treat it
          // exactly like a failure so no success copy can ever appear over
          // an unmoved wallet.
          state = state.copyWith(isSubmitting: false);
          if (context.mounted) {
            ErrorPresenter.showTechnical(
              context,
              type: errorType,
              detail: 'request_payout answered without success=true',
              extra: {'amount': '$amount', ..._scopeExtra},
            );
          }
          return;
        }
        state = state.copyWith(
          isSubmitting: false,
          lastRequestId: data.requestId,
          lastAmount: data.amount,
          balanceAfterHold: data.newBalance,
        );
        // The merchant IS the signed-in user, so the cached profile wallet
        // is the seller balance every hub surface reads; mirroring the
        // post-hold figure there is what makes them all agree at once.
        // Best-effort by design (see WalletBalanceCache).
        WalletBalanceCache.mirror(data.newBalance);
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
            extra: {'amount': '$amount', ..._scopeExtra},
          );
        }
      },
    );
  }
}
