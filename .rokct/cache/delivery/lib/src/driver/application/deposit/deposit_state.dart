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

import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';

/// Plain immutable state for the deposit flow (frames 49g/49h/49i).
/// Hand-written `copyWith`, like the sibling `driver_day_report.dart`, so
/// the slice stays analyzable without a build_runner pass.
class DepositState {
  const DepositState({
    this.destination,
    this.isLoadingDestination = false,
    this.destinationFailed = false,
    this.balance,
    this.balanceFailed = false,
    this.deposits = const [],
    this.isLoadingDeposits = false,
    this.depositsFailed = false,
    this.depositsLoadedOnce = false,
    this.isSubmitting = false,
    this.lastSubmitted,
  });

  /// Chip 975 — where the money goes. Null until read.
  final DepositDestination? destination;
  final bool isLoadingDestination;
  final bool destinationFailed;

  /// The wallet as the ledger holds it. NEVER net of a pending deposit.
  final num? balance;
  final bool balanceFailed;

  /// Chip 982 — the driver's own requests, newest first.
  final List<DepositRecord> deposits;
  final bool isLoadingDeposits;
  final bool depositsFailed;

  /// A read has completed, so an empty list means "never deposited", not
  /// "we have not looked yet".
  final bool depositsLoadedOnce;

  /// A submission is in flight; the sheet's commit goes inert so a
  /// double-tap cannot send two requests.
  final bool isSubmitting;

  /// The request just sent on this session — drawn as chip 979 the instant
  /// it lands, before the list re-reads.
  final DepositRecord? lastSubmitted;

  /// The newest still-live request, or null — what the status trail (chip
  /// 980) and the pending card (chip 979) are about.
  DepositRecord? get liveDeposit {
    for (final row in deposits) {
      if (row.isLive) return row;
    }
    final last = lastSubmitted;
    return (last != null && last.isLive) ? last : null;
  }

  DepositState copyWith({
    DepositDestination? destination,
    bool? isLoadingDestination,
    bool? destinationFailed,
    num? balance,
    bool? balanceFailed,
    List<DepositRecord>? deposits,
    bool? isLoadingDeposits,
    bool? depositsFailed,
    bool? depositsLoadedOnce,
    bool? isSubmitting,
    DepositRecord? lastSubmitted,
  }) =>
      DepositState(
        destination: destination ?? this.destination,
        isLoadingDestination: isLoadingDestination ?? this.isLoadingDestination,
        destinationFailed: destinationFailed ?? this.destinationFailed,
        balance: balance ?? this.balance,
        balanceFailed: balanceFailed ?? this.balanceFailed,
        deposits: deposits ?? this.deposits,
        isLoadingDeposits: isLoadingDeposits ?? this.isLoadingDeposits,
        depositsFailed: depositsFailed ?? this.depositsFailed,
        depositsLoadedOnce: depositsLoadedOnce ?? this.depositsLoadedOnce,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastSubmitted: lastSubmitted ?? this.lastSubmitted,
      );
}
