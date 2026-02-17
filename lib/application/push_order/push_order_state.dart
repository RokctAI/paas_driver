import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_order_state.freezed.dart';

@freezed
class PushOrderState with _$PushOrderState {
  const factory PushOrderState({
    @Default(false) bool isTimeOut,
    @Default(false) bool isLoading,
    @Default('0 s') String timerText,
  }) = _PushOrderState;

  const PushOrderState._();
}