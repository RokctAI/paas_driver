/// Plain immutable state rather than a `freezed` union (merchants_sdk
/// convention — see `src/manager/application/main/main_state.dart`).
///
/// The legacy slice (paas_driver `lib/application/story/story_state.dart`)
/// was a single-field `@freezed` class; a hand-written `copyWith` is
/// behavior-identical and keeps merchants_sdk analyzable without a
/// `build_runner` pass (and ships no `.freezed.dart`).
class StoryState {
  const StoryState({this.currentIndex = 0});

  final int currentIndex;

  StoryState copyWith({int? currentIndex}) =>
      StoryState(currentIndex: currentIndex ?? this.currentIndex);
}
