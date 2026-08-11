import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_order_state.freezed.dart';

@freezed
class CreateOrderState with _$CreateOrderState {
  const factory CreateOrderState({@Default(false) bool isCreating}) =
      _CreateOrderState;

  const CreateOrderState._();
}
