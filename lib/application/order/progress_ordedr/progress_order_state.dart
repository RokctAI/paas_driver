import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../infrastructure/models/data/order_detail.dart';

part 'progress_order_state.freezed.dart';

@freezed
abstract class ProgressOrderState with _$ProgressOrderState {
  const factory ProgressOrderState({
    @Default(false) bool isLoading,
    @Default([]) List<OrderDetailData> progressOrders,
    @Default(0) num totalProgressOrder,
  }) = _ProgressOrderState;

  const ProgressOrderState._();
}
