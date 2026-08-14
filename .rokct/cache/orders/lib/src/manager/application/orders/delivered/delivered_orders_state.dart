import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'delivered_orders_state.freezed.dart';

@freezed
class DeliveredOrdersState with _$DeliveredOrdersState {
  const factory DeliveredOrdersState({
    @Default(false) bool isLoading,
    @Default([]) List<OrderData> orders,
    @Default(0) int totalCount,
  }) = _DeliveredOrdersState;

  const DeliveredOrdersState._();
}
