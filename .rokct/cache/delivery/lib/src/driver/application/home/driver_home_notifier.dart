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

// The state behind the driver home composition (design strip section 49,
// frames 49a, 49d, 49e, 49m).
//
// DELIBERATELY NOT FREEZED. Every other state class in this SDK is, and
// their generated parts are gitignored — which means a widget test that
// imports one cannot compile without a build_runner pass first. The home
// composition is the screen this section is actually about, so its state
// is hand-written and its widgets stay testable on a bare checkout.
//
// It owns no policy. The wallet floor is resolved by the SERVER
// (`get_deliveryman_work_status`, which shares
// `resolve_deliveryman_wallet_allowance` with the guard that refuses the
// work), and the day figures are summed by the SERVER
// (`get_deliveryman_order_report`). This notifier fetches and holds; it
// decides nothing.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_day_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverHomeState {
  const DriverHomeState({
    this.isLoading = false,
    this.report = const DriverDayReport(),
    this.workStatus = const DriverWorkStatus(),
    this.openJobsInZone = 0,
  });

  final bool isLoading;
  final DriverDayReport report;
  final DriverWorkStatus workStatus;

  /// The honest hook back to work on frame 49d's rest state: a count
  /// only, from the available-orders read, so it can be shown WITHOUT
  /// accepting anything.
  final int openJobsInZone;

  /// Frame 49m: the offer queue is replaced by the gate exactly when the
  /// server says new work has stopped. Never a client-side comparison.
  bool get isWorkPaused => !workStatus.canTakeWork;

  DriverHomeState copyWith({
    bool? isLoading,
    DriverDayReport? report,
    DriverWorkStatus? workStatus,
    int? openJobsInZone,
  }) => DriverHomeState(
    isLoading: isLoading ?? this.isLoading,
    report: report ?? this.report,
    workStatus: workStatus ?? this.workStatus,
    openJobsInZone: openJobsInZone ?? this.openJobsInZone,
  );
}

class DriverHomeNotifier extends StateNotifier<DriverHomeState> {
  DriverHomeNotifier(this._orders) : super(const DriverHomeState());

  final CourierOrdersRepositoryFacade _orders;

  /// Both reads for the day, with today on both bounds.
  ///
  /// A failure on either leg leaves the previous value in place rather
  /// than blanking the screen: a driver reading a stale earned figure is
  /// better served than one reading zero, and neither number is an
  /// instruction to act.
  Future<void> refresh() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final report = await _orders.getDayReport(from: today, to: today);
    if (!mounted) return;
    report.when(
      success: (data) => state = state.copyWith(report: data),
      failure: (_, __) {},
    );

    final status = await _orders.getWorkStatus();
    if (!mounted) return;
    status.when(
      success: (data) => state = state.copyWith(workStatus: data),
      failure: (_, __) {},
    );

    if (!mounted) return;
    state = state.copyWith(isLoading: false);
  }

  /// Frame 49d's "N jobs open in your zone" pill. Counted, never taken.
  Future<void> refreshOpenJobCount() async {
    final available = await _orders.getAvailableOrders(1);
    if (!mounted) return;
    available.when(
      success: (data) => state = state.copyWith(openJobsInZone: data.length),
      failure: (_, __) {},
    );
  }
}
