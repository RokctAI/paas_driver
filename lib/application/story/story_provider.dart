import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'story_notifier.dart';
import 'story_state.dart';

final storyProvider =
    StateNotifierProvider.autoDispose<StoryNotifier, StoryState>(
  (ref) => StoryNotifier(),
);
