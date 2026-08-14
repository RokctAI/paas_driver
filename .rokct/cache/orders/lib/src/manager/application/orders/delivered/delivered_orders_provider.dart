import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivered_orders_state.dart';
import 'delivered_orders_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final deliveredOrdersProvider =
    StateNotifierProvider<DeliveredOrdersNotifier, DeliveredOrdersState>(
  (ref) =>
      DeliveredOrdersNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
