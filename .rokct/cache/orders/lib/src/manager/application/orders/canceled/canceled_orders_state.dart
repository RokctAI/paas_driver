import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'canceled_orders_state.freezed.dart';

@freezed
class CanceledOrdersState with _$CanceledOrdersState {
  const factory CanceledOrdersState({
    @Default(false) bool isLoading,
    @Default([]) List<OrderData> orders,
    @Default(0) int totalCount,
  }) = _CanceledOrdersState;

  const CanceledOrdersState._();
}
