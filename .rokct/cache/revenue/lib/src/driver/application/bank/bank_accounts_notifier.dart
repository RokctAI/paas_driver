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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imported directly (not via handlers.dart) because ApiResult's `when` is an
// EXTENSION declared in the generated `api_result.freezed.dart` part.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';

import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/driver/application/bank/bank_accounts_state.dart';
import 'package:revenue_sdk/src/driver/presentation/bank/bank_grammar.dart';

/// The driver's bank-details slice (design strip frames 49n-49s).
///
/// ERROR WORDING (Ray's standing rule, decision-log entry 56, drawn as
/// exhibit 49s): a driver-facing failure shows ONE friendly named line and
/// nothing more. Never the server's sentence, and never a technical
/// distinction — a driver must not be shown the difference between a payout
/// provider that is down and one that was never configured, because that
/// difference is an operator's problem and telling him invites him to try to
/// solve it. The admin-grade detail (verbatim server message + status code)
/// rides the ONE telemetry door, [ErrorPresenter.showTechnical] ->
/// `TelemetryClient.logError` -> backend `log_frontend_error`.
///
/// [ErrorPresenter.show] is deliberately NOT used anywhere on this surface:
/// it echoes a definitive 4xx verbatim, and Frappe answers a `frappe.throw`
/// with 417 — inside that band — so the server's own wording would reach the
/// driver. The unconditional technical branch is the only one that honours
/// the rule.
///
/// HOW A NAMED LINE IS CHOSEN. It is chosen HERE, from what this app already
/// knows, never by reading the server's reply. Every refusal frame 49s names
/// is knowable on the device before a call is made — the missing account, the
/// duplicate, the pledged account — so each is predicted from state and
/// refused in our words. Everything the client cannot predict falls to the
/// one generic line while the real cause goes to telemetry. That is why the
/// `friendly:` argument below is always a key we authored, and never the
/// failure string.
class BankAccountsNotifier extends StateNotifier<BankAccountsState> {
  BankAccountsNotifier(this._repository) : super(const BankAccountsState());

  final DriverPayoutRepositoryFacade _repository;

  /// Telemetry bucket for everything that goes wrong on this surface.
  static const String errorType = 'driver_bank_account';

  /// Reads the accounts, and — best effort — the live payout requests that
  /// decide which of them can be removed.
  ///
  /// [context] is optional so the withdraw path can pre-read silently: frame
  /// 49n's whole point is that `request_payout` is never fired blind, and a
  /// snackbar fired from behind an unopened sheet would be worse than the
  /// dead end it replaces.
  Future<void> load({BuildContext? context}) async {
    if (state.isLoading) return;
    if (!await AppConnectivity.connectivity()) {
      if (context != null && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    state = state.copyWith(isLoading: true, failed: false);
    final response = await _repository.listBankAccounts();
    response.when(
      success: (accounts) {
        state = state.copyWith(
          accounts: accounts,
          isLoading: false,
          loadedOnce: true,
        );
      },
      failure: (failure, status) {
        state = state.copyWith(
          isLoading: false,
          failed: true,
          loadedOnce: true,
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
            extra: const {'op': 'list_bank_accounts'},
          );
        }
      },
    );
    await _loadLiveRequests();
  }

  /// The still-`Requested` payouts, read only to mark rows unremovable.
  ///
  /// Silent by design on failure: this is decoration on someone else's
  /// screen, and a driver who cannot see WHY a removal is blocked is far
  /// better served than one who cannot see his accounts at all. The backend
  /// blocks the removal either way (`payout.py:270-286`) and that refusal
  /// carries the same named line.
  Future<void> _loadLiveRequests() async {
    final response = await _repository.listPayoutRequests();
    response.when(
      success: (requests) {
        state = state.copyWith(
          liveRequests:
              requests.where((request) => request.isLive).toList(growable: false),
        );
      },
      failure: (_, __) {},
    );
  }

  /// Saves a new account (frames 49o / 49p).
  ///
  /// The three rules the backend has are enforced on the form before this is
  /// reached, and the duplicate — the one refusal the form cannot see in a
  /// single field — is predicted here against the list already held
  /// (`payout.py:198-203`), so the driver is refused in our words rather
  /// than handed a translated server sentence.
  ///
  /// Returns the saved account, or null when nothing was written.
  Future<BankAccountRecord?> add({
    required BuildContext context,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    String? branchCode,
    String? accountType,
    bool isDefault = false,
  }) async {
    if (state.isSaving) return null;

    if (isDuplicateAccount(
      state.accounts,
      accountNumber: accountNumber,
      bankName: bankName,
    )) {
      // Frame 49s: "You've already saved this account." Refused before the
      // call, so the server's own wording never has the chance to appear.
      AppHelpers.showCheckTopSnackBar(
        context,
        AppHelpers.getTranslation('youve_already_saved_this_account'),
      );
      return null;
    }

    if (!await AppConnectivity.connectivity()) {
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return null;
    }

    state = state.copyWith(isSaving: true);
    final response = await _repository.addBankAccount(
      accountHolderName: accountHolderName,
      bankName: bankName,
      accountNumber: accountNumber,
      branchCode: branchCode,
      accountType: accountType,
      isDefault: isDefault,
    );

    BankAccountRecord? saved;
    response.when(
      success: (account) {
        saved = account;
        state = state.copyWith(isSaving: false);
      },
      failure: (failure, status) {
        state = state.copyWith(isSaving: false);
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            friendly: AppHelpers.getTranslation(
              'we_couldnt_save_that_account_try_again_in_a_moment',
            ),
            extra: const {'op': 'add_bank_account'},
          );
        }
      },
    );

    // Re-read rather than splicing the answer in: the server decides the
    // default mark and may have moved it off another row (`:209-220`), and
    // a list assembled locally would disagree with the one the payout is
    // actually made against.
    if (saved != null) await load();
    return saved;
  }

  /// Removes an account (frame 49q, chip 1013).
  ///
  /// The one blocker is predicted from the trail already held, so the driver
  /// is told in his own terms that a payout is waiting rather than being
  /// allowed to tap and be refused.
  Future<bool> remove({
    required BuildContext context,
    required BankAccountRecord account,
  }) async {
    if (state.busyAccountId != null) return false;

    if (isRemovalBlocked(account.id, state.liveRequests)) {
      AppHelpers.showCheckTopSnackBar(
        context,
        AppHelpers.getTranslation('a_payout_is_still_waiting_on_this_account'),
      );
      return false;
    }

    if (!await AppConnectivity.connectivity()) {
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return false;
    }

    state = state.copyWith(busyAccountId: account.id);
    final response = await _repository.removeBankAccount(account.id);
    var removed = false;
    response.when(
      success: (ok) => removed = ok,
      failure: (failure, status) {
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            friendly: AppHelpers.getTranslation(
              'we_couldnt_remove_that_account_try_again_in_a_moment',
            ),
            extra: const {'op': 'remove_bank_account'},
          );
        }
      },
    );
    state = state.copyWith(clearBusyAccountId: true);
    await load();
    return removed;
  }

  /// Moves the default mark onto [account] (frame 49q, chip 1012).
  ///
  /// The mark is exclusive server-side, so this is a move and not a set: the
  /// previous default is cleared in the same call.
  Future<bool> makeDefault({
    required BuildContext context,
    required BankAccountRecord account,
  }) async {
    if (state.busyAccountId != null || account.isDefault) return false;

    if (!await AppConnectivity.connectivity()) {
      if (context.mounted) AppHelpers.showNoConnectionSnackBar(context);
      return false;
    }

    state = state.copyWith(busyAccountId: account.id);
    final response = await _repository.setDefaultBankAccount(account.id);
    var ok = false;
    response.when(
      success: (marked) => ok = marked,
      failure: (failure, status) {
        if (context.mounted) {
          ErrorPresenter.showTechnical(
            context,
            type: errorType,
            detail: failure,
            statusCode: status,
            friendly: AppHelpers.getTranslation(
              'we_couldnt_change_your_default_account_try_again_in_a_moment',
            ),
            extra: const {'op': 'set_default_bank_account'},
          );
        }
      },
    );
    state = state.copyWith(clearBusyAccountId: true);
    await load();
    return ok;
  }
}
