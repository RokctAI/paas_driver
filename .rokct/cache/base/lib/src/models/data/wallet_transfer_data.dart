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
