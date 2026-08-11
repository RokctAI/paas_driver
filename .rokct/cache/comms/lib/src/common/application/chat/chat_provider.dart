import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:comms_sdk/src/common/application/chat/chat_notifier.dart';
import 'package:comms_sdk/src/common/application/chat/chat_state.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
