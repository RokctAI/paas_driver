import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:base_sdk/src/services/tr_keys.dart';

part 'delivery_type_state.freezed.dart';

@freezed
class DeliveryTypeState with _$DeliveryTypeState {
  const factory DeliveryTypeState({
    @Default(TrKeys.delivery) String type,
  }) = _DeliveryTypeState;

  const DeliveryTypeState._();
}
