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

/// One `Payout Bank Account` as `api.payout.list_bank_accounts` serves it
/// (pay `wallet/frappe/src/tenant/api/payout.py:241-252`, default first then
/// newest, through `_account_payload` at `:159-169`).
///
/// The seventh doctype field, `user`, is deliberately absent: the endpoint
/// writes it from `frappe.session.user` (`payout.py:186, 222`), so it is
/// never a thing this app holds, sends or could get wrong.
///
/// NOTHING here is validated for shape. The backend enforces exactly three
/// rules on this record — non-empty on the required three, 140 characters on
/// every text field, and an account type drawn from the doctype's Select —
/// and the controller is a bare `pass` (`payout_bank_account.py:28-29`).
/// Design strip frame 49o states that on its face rather than implying a
/// check that does not exist.
class BankAccountRecord {
  const BankAccountRecord({
    required this.id,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    this.branchCode,
    this.accountType,
    this.isDefault = false,
  });

  factory BankAccountRecord.fromJson(Map<String, dynamic> json) =>
      BankAccountRecord(
        id: json['id']?.toString() ?? '',
        accountHolderName: _text(json['account_holder_name']) ?? '',
        bankName: _text(json['bank_name']) ?? '',
        accountNumber: _text(json['account_number']) ?? '',
        branchCode: _text(json['branch_code']),
        accountType: _text(json['account_type']),
        isDefault: isTruthyFlag(json['is_default']),
      );

  /// Every row of a `list_bank_accounts` answer.
  ///
  /// That def returns a BARE list, not the shared `api_response` envelope —
  /// the same shape as `list_payout_requests` and for the same reason, so
  /// the unwrapping is owned here rather than assumed. Anything that is not
  /// a list of maps parses to no rows: a driver who has never added an
  /// account legitimately has none, and that is the whole premise of frame
  /// 49n.
  static List<BankAccountRecord> listFrom(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) => BankAccountRecord.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// `is_default` rides as Frappe's Check field — 1/0 over the wire, but a
  /// bool or the strings "1"/"true" are all accepted rather than silently
  /// reading as not-default, which would show a driver two accounts with no
  /// mark on either.
  static bool isTruthyFlag(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == '1' || text == 'true';
  }

  /// The `Payout Bank Account` row name — what `request_payout` and
  /// `remove_bank_account` take as `bank_account`.
  final String id;

  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String? branchCode;
  final String? accountType;

  /// Exactly one of a driver's accounts carries this. The backend keeps it
  /// singular: marking a later account default clears the previous one
  /// (`payout.py:209-220`), the first account added becomes default whatever
  /// the switch said (`:205-207`), and removing the default promotes the
  /// newest survivor (`:288-300`).
  final bool isDefault;
}
