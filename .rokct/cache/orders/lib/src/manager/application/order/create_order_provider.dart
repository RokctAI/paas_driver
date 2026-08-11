import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_order_state.dart';
import 'create_order_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final createOrderProvider =
    StateNotifierProvider<CreateOrderNotifier, CreateOrderState>(
  (ref) => CreateOrderNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
