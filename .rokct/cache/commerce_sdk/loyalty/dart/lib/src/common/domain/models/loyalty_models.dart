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

/// Core loyalty domain objects. Deliberately backend-agnostic: points,
/// cashback and stamp-card programs all reduce to an account balance plus an
/// append-only transaction ledger.
class LoyaltyAccount {
  final String accountId;
  final String ownerId;
  final String program;
  final double balance;
  final DateTime updatedAt;

  const LoyaltyAccount({
    required this.accountId,
    required this.ownerId,
    required this.program,
    required this.balance,
    required this.updatedAt,
  });

  LoyaltyAccount copyWith({double? balance, DateTime? updatedAt}) {
    return LoyaltyAccount(
      accountId: accountId,
      ownerId: ownerId,
      program: program,
      balance: balance ?? this.balance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'ownerId': ownerId,
        'program': program,
        'balance': balance,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) => LoyaltyAccount(
        accountId: json['accountId'] as String? ?? json['id'] as String,
        ownerId: json['ownerId'] as String? ?? '',
        program: json['program'] as String? ?? 'default',
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

enum LoyaltyTransactionType { earn, redeem, adjust, expire }

class LoyaltyTransaction {
  final String transactionId;
  final String accountId;
  final LoyaltyTransactionType type;
  final double points;
  final String? reference;
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.transactionId,
    required this.accountId,
    required this.type,
    required this.points,
    this.reference,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'accountId': accountId,
        'type': type.name,
        'points': points,
        'reference': reference,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransaction(
        transactionId:
            json['transactionId'] as String? ?? json['id'] as String,
        accountId: json['accountId'] as String? ?? '',
        type: LoyaltyTransactionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => LoyaltyTransactionType.adjust,
        ),
        points: (json['points'] as num?)?.toDouble() ?? 0,
        reference: json['reference'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
