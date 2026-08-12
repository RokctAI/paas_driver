import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merchants_sdk/src/driver/application/story/story_state.dart';

/// Moved verbatim from paas_driver `lib/application/story/story_notifier.dart`
/// (driver migration S-D6): tracks which of the three intro-story slides is
/// showing so the installed StoryPage can drive its progress bars.
class StoryNotifier extends StateNotifier<StoryState> {
  StoryNotifier() : super(const StoryState());

  void changeIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}
