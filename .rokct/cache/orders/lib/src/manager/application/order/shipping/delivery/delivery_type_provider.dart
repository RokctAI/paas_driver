import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivery_type_state.dart';
import 'delivery_type_notifier.dart';

final deliveryTypeProvider =
    StateNotifierProvider<DeliveryTypeNotifier, DeliveryTypeState>(
  (ref) => DeliveryTypeNotifier(),
);
