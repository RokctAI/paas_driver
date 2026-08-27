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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/driver/application/statistics/statistics_state.dart';
import 'package:revenue_sdk/src/driver/infrastructure/models/chart.dart';

/// Straight port of `paas_driver`'s `StatisticsNotifier`
/// (`lib/application/statistics/statistics_notifier.dart`), moved SDK-side so
/// the installed driver income templates stop depending on host application
/// code.
///
/// Differences from the host copy, both about keeping `charts_flutter` out of
/// this SDK (see [OrdinalSales]):
/// - `addListInfo()` became [addChartInfo]: it emits the plain
///   `List<OrdinalSales>` day/sales rows; the installed income template maps
///   them into a `charts_flutter` `Series` host-side (including the
///   brand-primary series color the host copy applied here).
/// - The state field is `chartData` rather than a prebuilt `Series` list.
///
/// The pre-fork notifier also carried fetchStatisticsOrder /
/// fetchStatisticsOrderByDay / fetchStatisticsOrderPage over
/// `getStatisticsOrder`. No page or widget called any of them (verified by
/// grep before the host port), so they are not carried over; the facade still
/// declares getStatisticsOrder for when a consumer materialises.
class StatisticsNotifier extends StateNotifier<StatisticsState> {
  StatisticsNotifier(this._courierStatistics) : super(const StatisticsState());

  final CourierStatisticsRepositoryFacade _courierStatistics;

  Future<void> fetchStatistics({
    required DateTime endTime,
    required DateTime startTime,
  }) async {
    if (state.countData == null) {
      state = state.copyWith(isLoading: true);
    }
    final response = await _courierStatistics.getStatistics(
      startTime: startTime,
      endTime: endTime,
    );
    response.when(
      success: (data) {
        if (state.countData == null) {
          state = state.copyWith(countData: data, isLoading: false);
        } else {
          state = state.copyWith(countData: data);
        }
        addChartInfo();
      },
      failure: (fail, status) {
        if (state.countData == null) {
          state = state.copyWith(isLoading: false);
        }
        debugPrint('==> error with fetching statistics $fail');
      },
    );
  }

  void addChartInfo() {
    final List<OrdinalSales> day = [];
    state.countData?.data?.chart?.forEach((element) {
      day.add(OrdinalSales(
        day: DateFormat('dd MMM').format(element.time ?? DateTime.now()),
        sales: element.totalPrice?.floor() ?? 0,
      ));
    });
    state = state.copyWith(chartData: day);
  }
}
