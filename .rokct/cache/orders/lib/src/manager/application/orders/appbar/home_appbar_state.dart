import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_appbar_state.freezed.dart';

@freezed
class HomeAppbarState with _$HomeAppbarState {
  const factory HomeAppbarState({
    @Default('') String title,
    @Default(0) int totalCount,
    @Default(0) int index,
  }) = _HomeAppbarState;

  const HomeAppbarState._();
}
