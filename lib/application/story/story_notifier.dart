import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'story_state.dart';

class StoryNotifier extends StateNotifier<StoryState> {
  StoryNotifier() : super(const StoryState());

  void changeIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}
