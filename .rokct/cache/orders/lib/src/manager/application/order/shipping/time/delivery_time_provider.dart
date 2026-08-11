import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivery_time_state.dart';
import 'delivery_time_notifier.dart';

final deliveryTimeProvider =
    StateNotifierProvider<DeliveryTimeNotifier, DeliveryTimeState>(
  (ref) => DeliveryTimeNotifier(),
);
