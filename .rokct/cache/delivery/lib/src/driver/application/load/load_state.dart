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

import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';

/// Plain immutable state for the van-sales slice. Hand-written `copyWith`,
/// like the sibling `deposit_state.dart`, so the slice stays analyzable
/// without a build_runner pass.
class DriverLoadState {
  const DriverLoadState({
    this.loads = const [],
    this.isLoading = false,
    this.loadedOnce = false,
    this.failed = false,
    this.isSubmitting = false,
    this.lastSale,
    this.closedLoad,
  });

  /// Every load the server handed back, in its order.
  final List<DriverLoad> loads;

  final bool isLoading;

  /// A read has completed, so an empty list means "no load issued", not
  /// "we have not looked yet". The empty state must never show before the
  /// first answer.
  final bool loadedOnce;

  final bool failed;

  /// A sale, a return or a close is in flight; the commit goes inert so a
  /// double-tap cannot sell the same stock twice.
  final bool isSubmitting;

  /// The sale just made on this session — the order id and the cash to
  /// collect, which the success sheet names.
  final DriverLoadSale? lastSale;

  /// The load as `close_load` answered it: per-line variance and totals.
  final DriverLoad? closedLoad;

  /// The loads still the driver's to work.
  List<DriverLoad> get openLoads =>
      loads.where((load) => load.isOpen).toList(growable: false);

  bool get hasOpenLoad => openLoads.isNotEmpty;

  /// What the home tile counts: units still on the van across every open
  /// load.
  num get openRemainingQty =>
      openLoads.fold<num>(0, (sum, load) => sum + load.remainingQtyTotal);

  /// What the home tile shows as a figure: the open loads' remaining value
  /// at the load prices.
  num get openRemainingTotal =>
      openLoads.fold<num>(0, (sum, load) => sum + load.remainingTotal);

  /// The load with [id] as this slice currently holds it, or null once the
  /// server has stopped sending it.
  DriverLoad? loadById(String id) {
    for (final load in loads) {
      if (load.id == id) return load;
    }
    return null;
  }

  DriverLoadState copyWith({
    List<DriverLoad>? loads,
    bool? isLoading,
    bool? loadedOnce,
    bool? failed,
    bool? isSubmitting,
    DriverLoadSale? lastSale,
    DriverLoad? closedLoad,
  }) =>
      DriverLoadState(
        loads: loads ?? this.loads,
        isLoading: isLoading ?? this.isLoading,
        loadedOnce: loadedOnce ?? this.loadedOnce,
        failed: failed ?? this.failed,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastSale: lastSale ?? this.lastSale,
        closedLoad: closedLoad ?? this.closedLoad,
      );
}
