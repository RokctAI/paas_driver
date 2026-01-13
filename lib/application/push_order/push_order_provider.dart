import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_order_notifier.dart';
import 'push_order_state.dart';

final pushOrderProvider =
    StateNotifierProvider.autoDispose<PushOrderNotifier, PushOrderState>(
  (_) => PushOrderNotifier(),
);
