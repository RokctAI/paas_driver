import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'on_a_way_orders_state.freezed.dart';

@freezed
class OnAWayOrdersState with _$OnAWayOrdersState {
  const factory OnAWayOrdersState({
    @Default(false) bool isLoading,
    @Default([]) List<OrderData> orders,
    @Default(0) int totalCount,
  }) = _OnAWayOrdersState;

  const OnAWayOrdersState._();
}
