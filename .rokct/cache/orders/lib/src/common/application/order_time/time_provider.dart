import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orders_sdk/src/common/application/order_time/time_notifier.dart';
import 'package:orders_sdk/src/common/application/order_time/time_state.dart';

final timeProvider = StateNotifierProvider<TimeNotifier, TimeState>(
  (ref) => TimeNotifier(),
);
