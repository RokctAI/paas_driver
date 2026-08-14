import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'new_orders_state.freezed.dart';

@freezed
abstract class NewOrdersState with _$NewOrdersState {
  const factory NewOrdersState({
    @Default(false) bool isLoading,
    @Default([]) List<OrderData> orders,
    @Default(0) int totalCount,
    RefreshController? refreshController,
  }) = _NewOrdersState;

  const NewOrdersState._();
}
