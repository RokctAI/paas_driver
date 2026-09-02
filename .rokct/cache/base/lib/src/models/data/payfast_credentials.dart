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


class PayFastCredentials {
  //final String merchantId;
  final String merchantKey;
  final String passphrase;
  final bool isSandbox;

  PayFastCredentials({
    //required this.merchantId,
    required this.merchantKey,
    required this.passphrase,
    this.isSandbox = true,
  });

  factory PayFastCredentials.fromJson(Map<String, dynamic> json) {
    return PayFastCredentials(
      // merchantId: json['merchant_id'] as String,
      merchantKey: json['merchant_key'] as String,
      passphrase: json['passphrase'] as String,
      isSandbox: json['is_sandbox'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'merchant_id': merchantId,
      'merchant_key': merchantKey,
      'passphrase': passphrase,
      'is_sandbox': isSandbox,
    };
  }
}
