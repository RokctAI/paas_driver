import 'package:freezed_annotation/freezed_annotation.dart';

import '../../infrastructure/models/data/order_detail.dart';

part 'order_state.freezed.dart';

@freezed
class OrderState with _$OrderState {
  const factory OrderState({
    @Default(false) bool isActiveLoading,
    @Default(false) bool isLoading,
    @Default(false) bool isAvailableLoading,
    @Default(false) bool isHistoryLoading,
    @Default(false) bool paymentType,
    @Default(null) OrderDetailData? order,
    @Default([]) List<OrderDetailData> activeOrders,
    @Default([]) List<OrderDetailData> availableOrders,
    @Default([]) List<OrderDetailData> historyOrders,
    @Default(0) num totalActiveOrder,
    @Default(0) int deliveryTime,
    @Default(0) int deliveryType,
  }) = _OrdrState;

  const OrderState._();
}
