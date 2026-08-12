import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merchants_sdk/src/driver/application/story/story_notifier.dart';
import 'package:merchants_sdk/src/driver/application/story/story_state.dart';

final storyProvider =
    StateNotifierProvider.autoDispose<StoryNotifier, StoryState>(
  (ref) => StoryNotifier(),
);
