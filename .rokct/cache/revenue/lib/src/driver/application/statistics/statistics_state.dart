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
