import 'package:freezed_annotation/freezed_annotation.dart';

part 'floating_state.freezed.dart';

/// Generic scroll-collapse state for floating chrome (the nav pill hides
/// while the content scrolls). Moved here from marketplace_sdk's
/// `floating_button/` — nothing marketplace-specific about it, and
/// [BottomNavigatorItem.shouldHide] reads exactly this signal.
@freezed
class FloatingState with _$FloatingState {
  const factory FloatingState({@Default(false) bool isScrolling}) =
      _FloatingState;

  const FloatingState._();
}
