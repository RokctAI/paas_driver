import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/application/push_order/push_order_notifier.dart';
import 'package:delivery_sdk/src/driver/application/push_order/push_order_state.dart';

final pushOrderProvider =
    StateNotifierProvider.autoDispose<PushOrderNotifier, PushOrderState>(
  (_) => PushOrderNotifier(),
);
