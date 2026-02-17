import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:driver/infrastructure/models/data/parcel_order.dart';

part 'parcel_state.freezed.dart';

@freezed
abstract class ParcelState with _$ParcelState {
  const factory ParcelState({
    @Default(false) bool isActiveLoading,
    @Default(false) bool isLoading,
    @Default(false) bool isAvailableLoading,
    @Default(false) bool isHistoryLoading,
    @Default(false) bool paymentType,
    @Default(null) ParcelOrder? order,
    @Default([]) List<ParcelOrder> activeOrders,
    @Default([]) List<ParcelOrder> availableOrders,
    @Default([]) List<ParcelOrder> historyOrders,
    @Default(0) num totalActiveOrder,
    @Default(0) int deliveryTime,
    @Default(0) int deliveryType,
  }) = _ParcelState;

  const ParcelState._();
}
