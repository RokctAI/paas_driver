import 'package:freezed_annotation/freezed_annotation.dart';

part 'orders_board_state.freezed.dart';

@freezed
abstract class OrdersBoardState with _$OrdersBoardState {
  const factory OrdersBoardState({
    @Default(<int>{}) Set<int> updatingIds,
  }) = _OrdersBoardState;

  const OrdersBoardState._();
}
