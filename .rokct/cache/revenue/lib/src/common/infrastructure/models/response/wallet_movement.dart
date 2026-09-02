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

/// One row of the driver's wallet statement — a `Wallet History` audit row
/// as `api.user.get_wallet_history` serves it.
///
/// WHY THE DIRECTION IS DERIVED AND NOT READ.  The ledger has two writers
/// and they do NOT agree on the sign of `amount`:
///
///  * wallet's own writer stores `abs(amount)` and puts the direction in
///    `transaction_type` (pay `wallet/frappe/src/tenant/api/payment/
///    payment.py:1372-1387` — a payout is written as type `Payout` with a
///    POSITIVE amount even though the money left);
///  * commerce's settlement writer stores a SIGNED amount, debits negative
///    (`commerce/orders/frappe/src/tenant/api/order/settlement.py:150-165`
///    — the delivery fee is `+fee` typed `Topup`, the delivery commission
///    `-commission` typed `Withdraw`, the collected cash `-gross` typed
///    `COD Collection`).
///
/// So [isCredit] reads the sign FIRST (a negative amount is always money
/// out, whoever wrote it) and only falls back to the type when the amount
/// is unsigned. Getting this wrong would draw a driver's cash debit as a
/// credit, which is the exact confusion frame 49f exists to end.
class WalletMovement {
  const WalletMovement({
    this.id,
    this.type,
    this.amount = 0,
    this.status,
    this.description,
    this.at,
  });

  /// Parses one row of the `data` list. Anything unexpected parses to a
  /// harmless zero-value row rather than throwing — a statement is a read,
  /// and one malformed row must not take the wallet screen down.
  factory WalletMovement.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return WalletMovement(
      id: json['name']?.toString(),
      type: json['transaction_type']?.toString(),
      amount: rawAmount is num
          ? rawAmount
          : num.tryParse('${rawAmount ?? ''}') ?? 0,
      status: json['status']?.toString(),
      // NOT served today: `get_wallet_history` selects name /
      // transaction_type / amount / status / creation only
      // (Users `users/frappe/src/tenant/api/user/user.py:1311-1315`), so
      // this is null in production right now and the row falls back to its
      // type for a label. It is parsed anyway because the column EXISTS on
      // the doctype and every writer fills it — adding it to that field
      // list is a one-line backend change, and when it lands these rows
      // start reading as frame 49f draws them with no client change.
      description: json['description']?.toString(),
      at: _parseDate(json['creation']),
    );
  }

  /// Every row of a `get_wallet_history` answer.
  ///
  /// That def wraps its rows in the shared `api_response` envelope —
  /// `{"data": [...], "status_code": 200}` — so the list is under `data`,
  /// unlike `list_payout_requests` which answers a BARE list. Anything that
  /// is not a list of maps parses to no rows: an empty statement is a
  /// legitimate answer for a driver who has never been paid, and a
  /// malformed one must not take his wallet screen down.
  static List<WalletMovement> listFrom(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) => WalletMovement.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    // Frappe serves `yyyy-MM-dd HH:mm:ss(.ffffff)`; DateTime.tryParse takes
    // it once the space is a `T`.
    return DateTime.tryParse(value.toString().trim().replaceFirst(' ', 'T'));
  }

  /// `Wallet History` row name.
  final String? id;

  /// The doctype's `transaction_type` Select, verbatim.
  final String? type;

  /// As stored — MAY be signed, may not. Use [magnitude] and [isCredit].
  final num amount;

  /// The doctype's `status` Select, verbatim.
  final String? status;

  /// The row's own sentence, when the server sends it.
  final String? description;

  /// `creation`.
  final DateTime? at;

  /// Transaction types that are money OUT when the amount carries no sign.
  /// Taken from the doctype's Select options
  /// (`wallet_history.json` transaction_type).
  static const Set<String> debitTypes = {
    'Withdraw',
    'Payout',
    'Payment',
    'Loan Repayment',
    'COD Collection',
  };

  /// Money in?  Sign first, type second — see the class comment.
  bool get isCredit {
    if (amount < 0) return false;
    return !debitTypes.contains(type);
  }

  /// Always positive; the direction is [isCredit].
  num get magnitude => amount.abs();
}
