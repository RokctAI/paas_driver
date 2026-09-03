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

/// Narrow contract for the driver's bank-deposit surface — design strip
/// frames 49g (method chooser), 49h (deposit capture) and 49i (approval
/// states).
///
/// The endpoints behind it are wallet's `api.wallet.*` defs (pay
/// `wallet/frappe/src/tenant/api/wallet.py`) and the balance read is
/// `api.payment.get_wallet_balance`. This SDK does NOT depend on wallet_sdk
/// — paas_driver composes no wallet_sdk (ADR-005: an SDK's `lib/` imports
/// only base_sdk) — so the calls ride base_sdk's universal platform gateway
/// by prefix-free dotted name, exactly as [CourierRepository] calls
/// delivery's and Users' defs, and as revenue_sdk's payout repository calls
/// wallet's `api.payout.*`.
///
/// THE MONEY MODEL, which every screen on this seam must honour:
///
///  * [submitDeposit] moves NOTHING. The wallet stays exactly where it was
///    until a person has matched the slip against the bank statement.
///  * [listMyDeposits] is the control that prevents a double deposit:
///    under review, approved, rejected with the reason in words.
///  * Card top-ups never come here: they credit instantly through wallet's
///    `/wallet-topup` route when that SDK is composed.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';

abstract class DriverDepositRepositoryFacade {
  /// The tenant's pay-in account (chip 975) and whether bank deposits are
  /// accepted at all. Served in full — a driver at an ATM copies it — and
  /// masked on screen.
  Future<ApiResult<DepositDestination>> getDestination();

  /// The driver's balance as the wallet ledger holds it — negative when
  /// he owes (cash docked at Delivered). Never net of a pending deposit.
  Future<ApiResult<num>> getWalletBalance();

  /// Uploads the slip photograph at [slipPath] through the fleet's
  /// multipart gallery seam, then sends the deposit for approval:
  /// `submit_deposit_request(amount, method, reference, slip)`. The server
  /// generates the reference when [reference] is null.
  Future<ApiResult<DepositSubmitResponse>> submitDeposit({
    required double amount,
    required String slipPath,
    String method = DepositMethod.bankDeposit,
    String? reference,
    String? note,
  });

  /// The driver's own deposit requests, newest first.
  Future<ApiResult<List<DepositRecord>>> listMyDeposits();
}
