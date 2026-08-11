import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_cart_state.dart';
import 'order_cart_notifier.dart';

final orderCartProvider =
    StateNotifierProvider<OrderCartNotifier, OrderCartState>(
  (ref) => OrderCartNotifier(),
);
