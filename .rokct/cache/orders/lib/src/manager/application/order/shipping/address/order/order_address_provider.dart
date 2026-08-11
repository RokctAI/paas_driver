import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_address_state.dart';
import 'order_address_notifier.dart';

final orderAddressProvider =
    StateNotifierProvider<OrderAddressNotifier, OrderAddressState>(
  (ref) => OrderAddressNotifier(),
);
