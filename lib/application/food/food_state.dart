import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_state.freezed.dart';

@freezed
class FoodState with _$FoodState {
  const factory FoodState({
    @Default(true) bool toggle,
    @Default(0) int timeIndex,
  }) = _FoodState;

  const FoodState._();
}
