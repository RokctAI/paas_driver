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

/// Narrow contract for the driver's payout (withdraw) surface.
///
/// Lives in `common/` for the same reason as
/// [CourierStatisticsRepositoryFacade]: the composer's role-stripping
/// deletes the non-matching role folder from an app's cache, so a seam the
/// barrel exports — and the response type its signature names — has to
/// survive that strip. Only the concrete `DriverPayoutRepository` is
/// driver-only and stays in `driver/`.
///
/// The endpoint behind it is wallet's `api.payout.request_payout`. This SDK
/// does NOT depend on wallet_sdk (paas_driver's pubspec composes no
/// wallet_sdk); the call rides base_sdk's universal platform gateway by
/// prefix-free dotted name, exactly as `CourierStatisticsRepository`
/// already calls delivery's and map's defs.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/bank_account_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_record.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/payout_request_response.dart';

abstract class DriverPayoutRepositoryFacade {
  /// Ask the admin to pay [amount] out to the driver's bank account (his
  /// default account when [bankAccount] is not named).
  ///
  /// The server debits the wallet immediately and answers the new balance;
  /// it refuses a non-positive amount, an amount above the CURRENT balance
  /// (re-checked under a row lock), and a driver with no bank account on
  /// file.
  Future<ApiResult<PayoutRequestResponse>> requestPayout({
    required double amount,
    String? bankAccount,
  });

  /// The driver's own payout requests, newest first — the trail behind
  /// design strip frame 49k.
  ///
  /// Every state it can report is already implemented server-side:
  /// `Requested` is the only live one, `Paid` / `Rejected` / `Cancelled`
  /// are terminal (`wallet_payout_request.py:52`), and a rejection or a
  /// cancellation has ALREADY credited the money back through
  /// `_release_hold` (`:118-150`) by the time it is read here. Resolution
  /// is desk-side; this app only reads.
  Future<ApiResult<List<PayoutRequestRecord>>> listPayoutRequests();

  /// The driver's saved bank accounts, default first then newest
  /// (`payout.py:241-252`) — design strip frames 49n and 49q.
  ///
  /// This is the read that makes frame 49n possible: the withdraw sheet asks
  /// for it BEFORE it offers an amount field, so a driver with no account on
  /// file meets an explanation instead of a refusal, and `request_payout` is
  /// never fired blind. Nothing is held and no request is sent.
  Future<ApiResult<List<BankAccountRecord>>> listBankAccounts();

  /// Register a bank account to be paid out to (`payout.py:176-239`) —
  /// design strip frame 49o.
  ///
  /// The endpoint takes exactly these six arguments and no more; the
  /// doctype's seventh field, `user`, is written from the session
  /// (`:186, 222`). The server refuses a blank required field, any field
  /// over 140 characters, an account type outside the doctype's Select, and
  /// a duplicate keyed on user + number + bank. It does NOT check the shape
  /// of the account number — nothing in this path does.
  ///
  /// The first account a driver adds becomes his default whatever
  /// [isDefault] says (`:205-207`), and a later one marked default clears
  /// the previous mark (`:209-220`).
  Future<ApiResult<BankAccountRecord>> addBankAccount({
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    String? branchCode,
    String? accountType,
    bool isDefault = false,
  });

  /// Remove one of the driver's saved accounts (`payout.py:254-302`).
  ///
  /// Refused while a still-`Requested` payout names it (`:270-286`); when
  /// the removed row held the default, the newest survivor takes it over
  /// (`:288-300`), so a driver is never left with accounts and no mark.
  Future<ApiResult<bool>> removeBankAccount(String bankAccount);

  /// Move the default mark onto [bankAccount] — design strip frame 49q,
  /// chip 1012.
  ///
  /// Backed by `api.payout.set_default_bank_account`. See the note on the
  /// concrete repository: this is the ONE call on this surface that the
  /// shipped backend did not already have, and the withdraw path is
  /// deliberately built so that nothing depends on it.
  Future<ApiResult<bool>> setDefaultBankAccount(String bankAccount);
}
