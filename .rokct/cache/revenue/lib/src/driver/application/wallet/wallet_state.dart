// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
