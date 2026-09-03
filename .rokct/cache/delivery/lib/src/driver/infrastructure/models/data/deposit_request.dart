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

/// Typed shapes for wallet's `api.wallet.*` deposit defs as the driver
/// reads them (pay `wallet/frappe/src/tenant/api/wallet.py`). Hand-written,
/// no codegen, matching the sibling `driver_day_report.dart`.
library;

/// The doctype's `method` Select, verbatim.
abstract final class DepositMethod {
  static const String bankDeposit = 'Bank Deposit';
  static const String eft = 'EFT';
}

/// The doctype's `status` Select, verbatim: Draft / Pending / Approved /
/// Rejected. [unknown] exists so a status added server-side later renders
/// as an unlabelled row instead of throwing on a money screen.
enum DepositStatus {
  draft,
  pending,
  approved,
  rejected,
  unknown;

  static DepositStatus parse(dynamic value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'draft':
        return DepositStatus.draft;
      case 'pending':
        return DepositStatus.pending;
      case 'approved':
        return DepositStatus.approved;
      case 'rejected':
        return DepositStatus.rejected;
      default:
        return DepositStatus.unknown;
    }
  }

  /// Still waiting on a person — the only live state.
  bool get isLive => this == DepositStatus.pending;
}

num _num(dynamic value) =>
    value is num ? value : num.tryParse('${value ?? ''}') ?? 0;

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString().trim().replaceFirst(' ', 'T'));
}

Map<String, dynamic> _map(dynamic body) {
  final data =
      body is Map && body.containsKey('message') ? body['message'] : body;
  return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
}

/// Chip 975 — where the money physically goes. `get_deposit_destination`
/// serves the tenant's `Wallet Deposit Settings` in full.
class DepositDestination {
  const DepositDestination({
    required this.accepting,
    this.accountHolderName,
    this.bankName,
    this.accountNumber,
    this.branchCode,
    this.accountType,
    this.instructions,
  });

  factory DepositDestination.fromJson(dynamic body) {
    final json = _map(body);
    return DepositDestination(
      accepting: json['accepting'] == true || json['accepting'] == 1,
      accountHolderName: _text(json['account_holder_name']),
      bankName: _text(json['bank_name']),
      accountNumber: _text(json['account_number']),
      branchCode: _text(json['branch_code']),
      accountType: _text(json['account_type']),
      instructions: _text(json['instructions']),
    );
  }

  /// False when the tenant switched bank deposits off OR has no account
  /// configured — either way there is nowhere to pay into.
  final bool accepting;
  final String? accountHolderName;
  final String? bankName;
  final String? accountNumber;
  final String? branchCode;
  final String? accountType;
  final String? instructions;

  /// `•••• 4417` on screen; the whole number rides Copy.
  String get maskedAccountNumber {
    final digits = (accountNumber ?? '').trim();
    if (digits.length <= 4) return digits;
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  /// `Std Bank · Cheque` — the bank line under the holder's name.
  String get bankLine => [bankName, accountType]
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .join(' · ');
}

/// One `Wallet Deposit Request` row as `list_deposit_requests` serves it.
class DepositRecord {
  const DepositRecord({
    required this.id,
    required this.amount,
    required this.status,
    this.method,
    this.reference,
    this.slipUrl,
    this.rejectionReason,
    this.submittedAt,
    this.resolvedAt,
    this.credited = false,
  });

  factory DepositRecord.fromJson(Map<String, dynamic> json) => DepositRecord(
        id: json['id']?.toString() ?? '',
        amount: _num(json['amount']),
        status: DepositStatus.parse(json['status']),
        method: _text(json['method']),
        reference: _text(json['reference']),
        slipUrl: _text(json['slip']),
        rejectionReason: _text(json['rejection_reason']),
        submittedAt: _date(json['submitted_at']),
        resolvedAt: _date(json['resolved_at']),
        credited: json['credited'] == true || _num(json['credited']) == 1,
      );

  /// Every row of a `list_deposit_requests` answer — a BARE list, newest
  /// first. Anything else parses to no rows: a driver who has never
  /// deposited legitimately has none.
  static List<DepositRecord> listFrom(dynamic body) {
    final data =
        body is Map && body.containsKey('message') ? body['message'] : body;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) => DepositRecord.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  final String id;
  final num amount;
  final DepositStatus status;
  final String? method;

  /// Chip 977 — the string the office matches the slip on; the one thing a
  /// driver on the phone reads out.
  final String? reference;
  final String? slipUrl;

  /// Chip 981 — in words, only on a Rejected row. The server refuses a
  /// rejection without one.
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? resolvedAt;
  final bool credited;

  bool get isLive => status.isLive;
}

/// `submit_deposit_request`'s answer. [balance] is the wallet AS IT STANDS:
/// the pending deposit is NOT subtracted, and the screen must not either.
class DepositSubmitResponse {
  const DepositSubmitResponse({
    required this.success,
    this.requestId,
    this.reference,
    this.amount,
    this.submittedAt,
    this.balance,
  });

  factory DepositSubmitResponse.fromJson(dynamic body) {
    final json = _map(body);
    return DepositSubmitResponse(
      success: json['success'] == true,
      requestId: _text(json['request_id']),
      reference: _text(json['reference']),
      amount: json['amount'] == null ? null : _num(json['amount']),
      submittedAt: _date(json['submitted_at']),
      balance: json['balance'] == null ? null : _num(json['balance']),
    );
  }

  final bool success;
  final String? requestId;
  final String? reference;
  final num? amount;
  final DateTime? submittedAt;
  final num? balance;

  /// The row as the history list will show it, so the status plane can
  /// draw the deposit the instant it is sent without a second read.
  DepositRecord toRecord({String method = DepositMethod.bankDeposit}) =>
      DepositRecord(
        id: requestId ?? '',
        amount: amount ?? 0,
        status: DepositStatus.pending,
        method: method,
        reference: reference,
        submittedAt: submittedAt,
      );
}
