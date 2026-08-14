import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'accepted_orders_state.freezed.dart';

@freezed
abstract class AcceptedOrdersState with _$AcceptedOrdersState {
  const factory AcceptedOrdersState({
    @Default(false) bool isLoading,
    @Default([]) List<OrderData> orders,
    @Default(0) int totalCount,
  }) = _AcceptedOrdersState;

  const AcceptedOrdersState._();
}
