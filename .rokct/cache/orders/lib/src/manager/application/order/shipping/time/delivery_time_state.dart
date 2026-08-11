import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_time_state.freezed.dart';

@freezed
class DeliveryTimeState with _$DeliveryTimeState {
  const factory DeliveryTimeState({@Default('') String deliveryDate}) =
      _DeliveryTimeState;

  const DeliveryTimeState._();
}
