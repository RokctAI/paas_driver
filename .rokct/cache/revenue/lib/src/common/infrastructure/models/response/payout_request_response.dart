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
