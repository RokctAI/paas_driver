import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_details_state.dart';
import 'order_details_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final orderDetailsProvider =
    StateNotifierProvider<OrderDetailsNotifier, OrderDetailsState>(
  (ref) => OrderDetailsNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
