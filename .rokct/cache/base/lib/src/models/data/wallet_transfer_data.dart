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

/// CashSend-style wallet transfer models (gateway cmds `api.transfer.*`).
///
/// Plain classes with manual fromJson per the base_sdk data-model
/// convention (freezed is reserved for riverpod state classes).

/// Answer of `api.transfer.confirm_recipient`: ONLY the one matching
/// user's name fields — never a list, never an email (anti-enumeration
/// contract of the phone-confirm send path).
class WalletRecipientData {
  final String? firstName;
  final String? lastName;
  final String? fullName;

  WalletRecipientData({
    this.firstName,
    this.lastName,
    this.fullName,
  });

  factory WalletRecipientData.fromJson(Map<String, dynamic> json) {
    return WalletRecipientData(
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      fullName: json['full_name']?.toString(),
    );
  }
}

/// Answer of `api.transfer.generate_receive_claim`: the receiver's pending
/// claim — a 6-digit code linked to receiver + exact amount, valid until
/// [expiresAt]. Shown only to the receiver in-app; handed to the sender
/// out-of-band (never pushed or SMSed).
class WalletReceiveClaimData {
  final String? code;
  final double? amount;
  final String? expiresAt;

  WalletReceiveClaimData({
    this.code,
    this.amount,
    this.expiresAt,
  });

  factory WalletReceiveClaimData.fromJson(Map<String, dynamic> json) {
    return WalletReceiveClaimData(
      code: json['code']?.toString(),
      amount: (json['amount'] as num?)?.toDouble(),
      expiresAt: json['expires_at']?.toString(),
    );
  }
}

/// Answer of `api.transfer.send_wallet_balance` (both the phone and the
/// receive-code modes).
class WalletTransferData {
  final bool success;
  final String? recipientName;
  final double? amount;
  final double? newBalance;

  WalletTransferData({
    this.success = false,
    this.recipientName,
    this.amount,
    this.newBalance,
  });

  factory WalletTransferData.fromJson(Map<String, dynamic> json) {
    return WalletTransferData(
      success: json['success'] == true,
      recipientName: json['recipient_name']?.toString(),
      amount: (json['amount'] as num?)?.toDouble(),
      newBalance: (json['new_balance'] as num?)?.toDouble(),
    );
  }
}
