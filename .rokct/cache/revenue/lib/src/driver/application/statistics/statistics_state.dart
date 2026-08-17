// Copyright (c) 2026 RokctAI
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

import 'package:revenue_sdk/src/common/infrastructure/models/response/courier_statistics_income_response.dart';
import 'package:revenue_sdk/src/driver/infrastructure/models/chart.dart';

/// Plain immutable state rather than a `freezed` union, matching the manager
/// slice (`src/manager/application/statistics/statistics_state.dart`): a
/// hand-written `copyWith` keeps `revenue_sdk` analyzable without a
/// `build_runner` pass.
///
/// The legacy `paas_driver` state carried a
/// `List<Series<OrdinalSales, String>> list` for `charts_flutter`. That would
/// drag the chart library into this SDK, so the field is [chartData]
/// (`List<OrdinalSales>`) instead — the installed income template builds the
/// `Series` host-side, where `charts_flutter` lives.
class StatisticsState {
  const StatisticsState({
    this.isLoading = false,
    this.isRefresh = true,
    this.chartData = const [],
    this.countData,
  });

  final bool isLoading;
  final bool isRefresh;
  final List<OrdinalSales> chartData;
  final CourierStatisticsIncomeResponse? countData;

  StatisticsState copyWith({
    bool? isLoading,
    bool? isRefresh,
    List<OrdinalSales>? chartData,
    CourierStatisticsIncomeResponse? countData,
  }) =>
      StatisticsState(
        isLoading: isLoading ?? this.isLoading,
        isRefresh: isRefresh ?? this.isRefresh,
        chartData: chartData ?? this.chartData,
        countData: countData ?? this.countData,
      );
}
