import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'order_address_state.freezed.dart';

@freezed
class OrderAddressState with _$OrderAddressState {
  const factory OrderAddressState({
    TextEditingController? textController,
    LocationModel? location,
    @Default('') String entrance,
    @Default('') String floor,
    @Default('') String house,
  }) = _OrderAddressState;

  const OrderAddressState._();
}
