import 'package:charts_flutter/flutter.dart';
import 'package:driver/infrastructure/models/models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics_state.freezed.dart';

@freezed
abstract class StatisticsState with _$StatisticsState {
  const factory StatisticsState({
    @Default(false) bool isLoading,
    @Default(true) bool isRefresh,
    @Default([]) List<Series<OrdinalSales, String>> list,
    @Default([]) List<StatisticsOrder> listOfOrder,
    StatisticsIncomeResponse? countData,
  }) = _StatisticsState;

  const StatisticsState._();
}
