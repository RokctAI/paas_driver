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

/// One `Wallet Payout Request` as `api.payout.list_payout_requests` serves
/// it (pay `wallet/frappe/src/tenant/api/payout.py:432-471`, newest first,
/// capped at 100 rows).
///
/// The banking details are a SNAPSHOT taken onto the request row at request
/// time (`payout.py:349-368`), not a pointer at the driver's saved account —
/// so what a history row shows is literally what the payer read, even if the
/// driver has since removed that account.
class PayoutRequestRecord {
  const PayoutRequestRecord({
    required this.id,
    required this.amount,
    required this.status,
    this.requestedAt,
    this.resolvedAt,
    this.bankAccountId,
    this.bankName,
    this.accountNumber,
    this.accountHolderName,
    this.accountType,
  });

  factory PayoutRequestRecord.fromJson(Map<String, dynamic> json) {
    final bank = json['bank_account'];
    final Map<String, dynamic> account =
        bank is Map ? Map<String, dynamic>.from(bank) : <String, dynamic>{};
    final rawAmount = json['amount'];
    return PayoutRequestRecord(
      id: json['id']?.toString() ?? '',
      amount: rawAmount is num
          ? rawAmount
          : num.tryParse('${rawAmount ?? ''}') ?? 0,
      status: PayoutStatus.parse(json['status']),
      requestedAt: _parseDate(json['requested_at']),
      resolvedAt: _parseDate(json['resolved_at']),
      bankAccountId: _text(account['id']),
      bankName: _text(account['bank_name']),
      accountNumber: _text(account['account_number']),
      accountHolderName: _text(account['account_holder_name']),
      accountType: _text(account['account_type']),
    );
  }

  /// Every row of a `list_payout_requests` answer.
  ///
  /// That def returns a BARE list, not the shared `api_response` envelope
  /// the wallet statement uses — the two driver money reads genuinely
  /// differ in shape, which is why each model owns its own unwrapping.
  /// Anything that is not a list of maps parses to no rows: a driver who
  /// has never withdrawn legitimately has none.
  static List<PayoutRequestRecord> listFrom(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) =>
            PayoutRequestRecord.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString().trim().replaceFirst(' ', 'T'));
  }

  /// The request row's name. There is no naming series on the doctype, so
  /// this is a Frappe hash — never shown to the driver as a reference.
  final String id;

  final num amount;
  final PayoutStatus status;
  final DateTime? requestedAt;
  final DateTime? resolvedAt;

  /// The `Payout Bank Account` row this request was made against, as the
  /// def serves it (`payout.py:459`). Plain data, not a Link — the account
  /// can be removed once the request is resolved without breaking the row
  /// (`wallet_payout_request.json:42`), so this may name an account that no
  /// longer exists. It is used for exactly one thing: telling the bank-
  /// accounts list which row a still-`Requested` payout is holding open
  /// (`payout.py:270-286`), which is what frame 49q draws on the blocked row.
  final String? bankAccountId;

  final String? bankName;
  final String? accountNumber;
  final String? accountHolderName;
  final String? accountType;

  /// Still in flight — the only non-terminal state
  /// (`wallet_payout_request.py:52` TERMINAL_STATUSES).
  bool get isLive => status == PayoutStatus.requested;

  /// The money came back. `Rejected` and `Cancelled` both run the hold
  /// through `_release_hold` (`wallet_payout_request.py:118-150`), latched
  /// by `hold_released` so it happens at most once. `Paid` does NOT credit
  /// back — that money genuinely went to the bank.
  bool get isCreditedBack =>
      status == PayoutStatus.rejected || status == PayoutStatus.cancelled;
}

/// The doctype's `status` Select, verbatim
/// (`wallet_payout_request.json`: Requested / Paid / Rejected / Cancelled).
///
/// [unknown] exists so a status added server-side later renders as an
/// unlabelled row instead of throwing on a driver's money screen.
enum PayoutStatus {
  requested,
  paid,
  rejected,
  cancelled,
  unknown;

  static PayoutStatus parse(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'requested':
        return PayoutStatus.requested;
      case 'paid':
        return PayoutStatus.paid;
      case 'rejected':
        return PayoutStatus.rejected;
      case 'cancelled':
        return PayoutStatus.cancelled;
      default:
        return PayoutStatus.unknown;
    }
  }
}
