import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'ready_orders_state.freezed.dart';

@freezed
class ReadyOrdersState with _$ReadyOrdersState {
  const factory ReadyOrdersState({
    @Default(false) bool isLoading,
    @Default([]) List<OrderData> orders,
    @Default(0) int totalCount,
  }) = _ReadyOrdersState;

  const ReadyOrdersState._();
}
