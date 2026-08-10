import 'package:charts_flutter/flutter.dart';
import 'package:driver/infrastructure/models/models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:revenue_sdk/revenue_sdk.dart'
    show CourierStatisticsIncomeResponse;

part 'statistics_state.freezed.dart';

@freezed
class StatisticsState with _$StatisticsState {
  const factory StatisticsState({
    @Default(false) bool isLoading,
    @Default(true) bool isRefresh,
    @Default([]) List<Series<OrdinalSales, String>> list,
    CourierStatisticsIncomeResponse? countData,
  }) = _StatisticsState;

  const StatisticsState._();
}
