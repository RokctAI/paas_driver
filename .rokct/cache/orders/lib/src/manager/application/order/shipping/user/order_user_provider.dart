import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_user_state.dart';
import 'order_user_notifier.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_customers.dart';

final orderUserProvider =
    StateNotifierProvider<OrderUserNotifier, OrderUserState>(
  (ref) => OrderUserNotifier(resolvePosCustomersFacade()),
);
