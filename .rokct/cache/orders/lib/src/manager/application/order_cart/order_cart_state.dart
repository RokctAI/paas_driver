import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'order_cart_state.freezed.dart';

@freezed
abstract class OrderCartState with _$OrderCartState {
  const factory OrderCartState({
    @Default([]) List<Stock> stocks,
    @Default(0) num totalPrice,
  }) = _OrderCartState;

  const OrderCartState._();
}
