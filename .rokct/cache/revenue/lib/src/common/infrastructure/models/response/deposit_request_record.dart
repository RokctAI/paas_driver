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

/// A `Wallet Deposit Request`'s status as the wire spells it.
enum DepositRequestStatus {
  draft,
  pending,
  approved,
  rejected,
  unknown;

  static DepositRequestStatus parse(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'draft':
        return DepositRequestStatus.draft;
      case 'pending':
        return DepositRequestStatus.pending;
      case 'approved':
        return DepositRequestStatus.approved;
      case 'rejected':
        return DepositRequestStatus.rejected;
      default:
        return DepositRequestStatus.unknown;
    }
  }
}

/// One `Wallet Deposit Request` as `api.wallet.list_pending_deposit_requests`
/// serves it (pay `wallet/frappe/src/tenant/api/wallet.py`, oldest first,
/// with the requester's name because an approver matches a slip to a
/// person). The same shape, minus the user block, is what a driver's own
/// list returns.
class DepositRequestRecord {
  const DepositRequestRecord({
    required this.id,
    required this.amount,
    required this.status,
    this.user,
    this.userName,
    this.method,
    this.reference,
    this.slipUrl,
    this.note,
    this.balanceAtSubmit,
    this.submittedAt,
    this.resolvedAt,
    this.rejectionReason,
  });

  factory DepositRequestRecord.fromJson(Map<String, dynamic> json) {
    return DepositRequestRecord(
      id: _text(json['id']) ?? _text(json['name']) ?? '',
      amount: _num(json['amount']) ?? 0,
      status: DepositRequestStatus.parse(json['status']),
      user: _text(json['user']),
      userName: _text(json['user_name']),
      method: _text(json['method']),
      reference: _text(json['reference']),
      slipUrl: _text(json['slip']),
      note: _text(json['note']),
      balanceAtSubmit: _num(json['balance_at_submit']),
      submittedAt: _parseDate(json['submitted_at']),
      resolvedAt: _parseDate(json['resolved_at']),
      rejectionReason: _text(json['rejection_reason']),
    );
  }

  /// Every row of a bare-list answer. Anything that is not a list of maps
  /// parses to no rows: an empty queue is the normal state.
  static List<DepositRequestRecord> listFrom(dynamic data) {
    final rows = data is Map ? data['data'] : data;
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) =>
            DepositRequestRecord.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static num? _num(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString().trim().replaceFirst(' ', 'T'));
  }

  /// The request row's name — a Frappe hash, never shown as a reference.
  final String id;

  final num amount;
  final DepositRequestStatus status;

  /// The requester (User name) and display name.
  final String? user;
  final String? userName;

  /// `Bank Deposit` or `EFT`.
  final String? method;

  /// What the driver wrote on the slip (chip 977).
  final String? reference;

  /// The slip photo's URL (chip 976), uploaded through the gallery seam.
  final String? slipUrl;

  final String? note;

  /// The wallet as it stood when he sent it — kept for the record, so an
  /// approver sees what the deposit was against.
  final num? balanceAtSubmit;

  final DateTime? submittedAt;
  final DateTime? resolvedAt;
  final String? rejectionReason;

  /// Who to call it by on the card.
  String get displayName => userName ?? user ?? '';
}

/// What `approve_deposit_request` / `reject_deposit_request` answer.
class DepositResolution {
  const DepositResolution({
    required this.requestId,
    required this.approved,
    this.amount,
    this.newBalance,
    this.reason,
  });

  factory DepositResolution.fromJson(dynamic body) {
    final json = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    final approved = json['approved'] == true || json['approved'] == 1;
    return DepositResolution(
      requestId: json['request_id']?.toString() ?? '',
      approved: approved,
      amount: DepositRequestRecord._num(json['amount']),
      newBalance: DepositRequestRecord._num(json['new_balance']),
      reason: DepositRequestRecord._text(json['reason']),
    );
  }

  final String requestId;
  final bool approved;

  /// On approval: what was credited and the driver's balance after it.
  final num? amount;
  final num? newBalance;

  /// On rejection: the reason as the server stored it.
  final String? reason;
}
