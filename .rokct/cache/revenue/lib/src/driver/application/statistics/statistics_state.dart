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
