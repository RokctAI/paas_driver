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

// The two reads behind the driver home composition (design strip
// section 49, frames 49a / 49d / 49m).
//
// Hand-written parsers, matching order_detail.dart's house style, so
// nothing here needs code generation to compile.

/// `get_deliveryman_order_report`'s `data` block, for one date range.
///
/// [lastFee], [cashOnHand] and [cashOrderCount] are the three fields
/// frames 49a and 49d stamped as "needs a field". They are derived
/// server-side from rows the report already reads and are ADDITIVE — an
/// older backend simply omits them and they parse as zero, which is the
/// correct reading (an unmigrated site has no COD column to sum).
class DriverDayReport {
  const DriverDayReport({
    this.earned = 0,
    this.deliveredCount = 0,
    this.totalCount = 0,
    this.lastFee = 0,
    this.cashOnHand = 0,
    this.cashOrderCount = 0,
  });

  /// `total_price` — delivery fees of Delivered work in the range.
  final num earned;

  /// `total_delivered_count`.
  final int deliveredCount;

  /// `total_count` — all statuses in the range.
  final int totalCount;

  /// `last_delivered_fee`.
  final num lastFee;

  /// `cash_on_hand` — COD recorded at the door, already docked from his
  /// wallet by settlement.
  final num cashOnHand;

  /// `cash_order_count`.
  final int cashOrderCount;

  factory DriverDayReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : json;
    return DriverDayReport(
      earned: _num(map['total_price']),
      deliveredCount: _int(map['total_delivered_count']),
      totalCount: _int(map['total_count']),
      lastFee: _num(map['last_delivered_fee']),
      cashOnHand: _num(map['cash_on_hand']),
      cashOrderCount: _int(map['cash_order_count']),
    );
  }
}

/// `get_deliveryman_work_status`'s `data` block — the wallet floor as
/// the SERVER resolved it (frame 49m, chips 990/991).
///
/// The client derives NONE of this. `allowance` resolves through the
/// per-driver override, then the tenant single, then the platform
/// default, and `canTakeWork` is the same comparison
/// `assert_deliveryman_can_take_work` makes, so the gate on screen can
/// never disagree with the guard that actually refuses the work.
class DriverWorkStatus {
  const DriverWorkStatus({
    this.allowance = 0,
    this.balance = 0,
    this.owing = 0,
    this.canTakeWork = true,
  });

  /// How far his wallet may go negative and still be offered new work.
  final num allowance;

  /// His Wallet balance, signed.
  final num balance;

  /// UNSIGNED magnitude he is behind — the frames state the position as
  /// a sentence, never as a signed number, and this is what they say it
  /// with.
  final num owing;

  /// Whether the server would let him accept a new job right now.
  ///
  /// Defaults TRUE so an older backend, or a failed read, never gates a
  /// driver who is in fact allowed to work. The server refuses at accept
  /// regardless; this flag only decides what he is told beforehand.
  final bool canTakeWork;

  factory DriverWorkStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : json;
    return DriverWorkStatus(
      allowance: _num(map['allowance']),
      balance: _num(map['balance']),
      owing: _num(map['owing']),
      canTakeWork: map['can_take_work'] == null
          ? true
          : map['can_take_work'] == true ||
                map['can_take_work'] == 1 ||
                map['can_take_work'] == '1',
    );
  }
}

num _num(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
