import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_state.freezed.dart';

@freezed
class StoryState with _$StoryState {
  const factory StoryState({@Default(0) int currentIndex}) = _StoryState;

  const StoryState._();
}
