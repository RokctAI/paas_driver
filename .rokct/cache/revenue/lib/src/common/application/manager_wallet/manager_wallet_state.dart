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

import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';

/// Plain immutable state for the manager wallet pane (design strip frame
/// 49l). Hand-written `copyWith`, matching the sibling slices, so
/// `revenue_sdk` stays analyzable without a `build_runner` pass.
class ManagerWalletState {
  const ManagerWalletState({
    this.accounts = const [],
    this.accountsLoadedOnce = false,
    this.accountsFailed = false,
    this.isLoadingAccounts = false,
    this.isSubmitting = false,
    this.selectedAccountId,
    this.lastRequestId,
    this.lastAmount,
    this.balanceAfterHold,
  });

  /// The signed-in manager's saved payout accounts, default first then
  /// newest, exactly as `list_bank_accounts` serves them.
  final List<BankAccountRecord> accounts;

  /// True once an accounts read has completed, successfully or not.
  /// Separates "no account on file" (frame 49n's premise) from "we have
  /// not looked yet".
  final bool accountsLoadedOnce;

  /// The accounts read did not land. The pane says so in one friendly line
  /// and does NOT open the no-account sheet: an unread list is not an empty
  /// one.
  final bool accountsFailed;

  final bool isLoadingAccounts;

  /// A request is in flight; the sheet's commit goes inert so a double-tap
  /// cannot fire two holds.
  final bool isSubmitting;

  /// The account the request will name. Passed EXPLICITLY on
  /// `request_payout` rather than left to the server's default, for the
  /// same reason the driver does (`_default_account` returns nothing when
  /// two rows are unmarked, `payout.py:137-157`).
  final String? selectedAccountId;

  /// `Wallet Payout Request` row name of the last accepted request.
  final String? lastRequestId;

  /// The amount the server actually held.
  final num? lastAmount;

  /// The balance the server reported AFTER the hold — the money has already
  /// left. Null until a request has been accepted on this pane; once set,
  /// the pane's card draws it in place of the host's snapshot.
  final num? balanceAfterHold;

  /// He has looked, and there is nothing there — the one condition on which
  /// the withdraw sheet is replaced by frame 49n's explanation.
  bool get hasNoAccount => accountsLoadedOnce && !accountsFailed && accounts.isEmpty;

  BankAccountRecord? get selectedAccount {
    for (final account in accounts) {
      if (account.id == selectedAccountId) return account;
    }
    return null;
  }

  ManagerWalletState copyWith({
    List<BankAccountRecord>? accounts,
    bool? accountsLoadedOnce,
    bool? accountsFailed,
    bool? isLoadingAccounts,
    bool? isSubmitting,
    String? selectedAccountId,
    bool clearSelectedAccountId = false,
    String? lastRequestId,
    num? lastAmount,
    num? balanceAfterHold,
  }) =>
      ManagerWalletState(
        accounts: accounts ?? this.accounts,
        accountsLoadedOnce: accountsLoadedOnce ?? this.accountsLoadedOnce,
        accountsFailed: accountsFailed ?? this.accountsFailed,
        isLoadingAccounts: isLoadingAccounts ?? this.isLoadingAccounts,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        selectedAccountId: clearSelectedAccountId
            ? null
            : (selectedAccountId ?? this.selectedAccountId),
        lastRequestId: lastRequestId ?? this.lastRequestId,
        lastAmount: lastAmount ?? this.lastAmount,
        balanceAfterHold: balanceAfterHold ?? this.balanceAfterHold,
      );
}
