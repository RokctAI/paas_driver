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

import 'package:revenue_sdk/src/common/infrastructure/models/response/wallet_movement.dart';

/// Plain immutable state, matching the statistics and withdraw slices (a
/// hand-written `copyWith` keeps `revenue_sdk` analyzable without a
/// `build_runner` pass).
///
/// [balance] is deliberately nullable and NOT defaulted to zero: "not read
/// yet" and "genuinely zero" are different things on a money screen, and
/// drawing an unread balance as zero over a real debt is the failure this
/// plane exists to prevent. The page shows the cached figure until a real
/// one arrives.
class DriverWalletState {
  const DriverWalletState({
    this.balance,
    this.movements = const [],
    this.isLoadingBalance = false,
    this.isLoadingMovements = false,
    this.balanceFailed = false,
    this.movementsFailed = false,
    this.feesThisMonth,
    this.showAllMovements = false,
  });

  /// The server's authoritative balance, once read. May be NEGATIVE and
  /// that is correct.
  final num? balance;

  /// The statement, newest first.
  final List<WalletMovement> movements;

  final bool isLoadingBalance;
  final bool isLoadingMovements;

  /// A read that did not land. The screen says so in one friendly line; the
  /// real cause has already gone to telemetry.
  final bool balanceFailed;
  final bool movementsFailed;

  /// Gross delivery fees earned in the current calendar month, from the
  /// driver's own order report. Null when it has not been read.
  final num? feesThisMonth;

  /// The statement starts folded to its first rows; "See all movements"
  /// unfolds what was already fetched rather than opening a screen nobody
  /// has approved.
  final bool showAllMovements;

  DriverWalletState copyWith({
    num? balance,
    List<WalletMovement>? movements,
    bool? isLoadingBalance,
    bool? isLoadingMovements,
    bool? balanceFailed,
    bool? movementsFailed,
    num? feesThisMonth,
    bool? showAllMovements,
  }) =>
      DriverWalletState(
        balance: balance ?? this.balance,
        movements: movements ?? this.movements,
        isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
        isLoadingMovements: isLoadingMovements ?? this.isLoadingMovements,
        balanceFailed: balanceFailed ?? this.balanceFailed,
        movementsFailed: movementsFailed ?? this.movementsFailed,
        feesThisMonth: feesThisMonth ?? this.feesThisMonth,
        showAllMovements: showAllMovements ?? this.showAllMovements,
      );
}
