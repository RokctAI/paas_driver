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

/// The answer `api.payout.request_payout` gives on success.
///
/// The wallet is debited AT REQUEST TIME (wallet payout.py: the request
/// endpoint takes the hold, so a pending request can never be outspent and
/// a payout can never drive the balance negative). [newBalance] is
/// therefore the balance the driver already has — not a projection — and
/// [amount] is money that has left his wallet and is waiting on the
/// admin's out-of-band bank transfer.
class PayoutRequestResponse {
  const PayoutRequestResponse({
    this.success = false,
    this.requestId,
    this.amount,
    this.newBalance,
  });

  factory PayoutRequestResponse.fromJson(Map<String, dynamic> json) =>
      PayoutRequestResponse(
        success: json['success'] == true,
        requestId: json['request_id']?.toString(),
        amount: json['amount'] is num ? json['amount'] as num : null,
        newBalance:
            json['new_balance'] is num ? json['new_balance'] as num : null,
      );

  /// True only when the server said so; anything else is a failure.
  final bool success;

  /// `Wallet Payout Request` row name, for the driver's reference.
  final String? requestId;

  /// The amount actually held, server-rounded to 2dp.
  final num? amount;

  /// The wallet balance AFTER the hold.
  final num? newBalance;
}
