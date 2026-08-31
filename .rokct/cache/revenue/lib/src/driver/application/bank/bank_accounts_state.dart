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

import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';

/// Plain immutable state for the driver's bank-details surface (design strip
/// frames 49n-49q). Hand-written `copyWith`, matching the sibling slices, so
/// `revenue_sdk` stays analyzable without a `build_runner` pass.
class BankAccountsState {
  const BankAccountsState({
    this.accounts = const [],
    this.liveRequests = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.busyAccountId,
    this.failed = false,
    this.loadedOnce = false,
  });

  /// Default first then newest, as `list_bank_accounts` serves them
  /// (`payout.py:241-252`).
  final List<BankAccountRecord> accounts;

  /// Still-`Requested` payouts, kept alongside the accounts for one purpose:
  /// deciding which rows cannot be removed (`payout.py:270-286`) so the
  /// refusal is drawn in the row rather than fetched by attempting it.
  ///
  /// A read failure here is NOT surfaced and does not set [failed]: not
  /// knowing which account is pledged must never stop a driver from seeing
  /// his accounts. The backend refuses the removal regardless, and that
  /// refusal reads as the friendly named line.
  final List<PayoutRequestRecord> liveRequests;

  final bool isLoading;

  /// A save is in flight; the form's Save button goes inert so a double-tap
  /// cannot write two accounts.
  final bool isSaving;

  /// The row currently being removed or promoted, so exactly that row reads
  /// as busy instead of the whole list.
  final String? busyAccountId;

  /// The accounts read did not land. One friendly line says so; the real
  /// cause has already gone to telemetry.
  final bool failed;

  /// True once an accounts read has completed, successfully or not.
  ///
  /// Load-bearing: it separates "he has no bank account" — the entire
  /// premise of frame 49n — from "we have not looked yet". Offering the
  /// no-account explanation before a read has landed would tell a driver who
  /// HAS an account that he has none.
  final bool loadedOnce;

  /// He has looked, and there is nothing there. The condition frame 49n
  /// draws, and the only one on which the withdraw sheet is replaced by the
  /// explanation.
  bool get hasNoAccount => loadedOnce && !failed && accounts.isEmpty;

  BankAccountsState copyWith({
    List<BankAccountRecord>? accounts,
    List<PayoutRequestRecord>? liveRequests,
    bool? isLoading,
    bool? isSaving,
    String? busyAccountId,
    bool clearBusyAccountId = false,
    bool? failed,
    bool? loadedOnce,
  }) =>
      BankAccountsState(
        accounts: accounts ?? this.accounts,
        liveRequests: liveRequests ?? this.liveRequests,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        busyAccountId:
            clearBusyAccountId ? null : (busyAccountId ?? this.busyAccountId),
        failed: failed ?? this.failed,
        loadedOnce: loadedOnce ?? this.loadedOnce,
      );
}
