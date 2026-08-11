import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_state.dart';
import 'order_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final orderProvider =
    StateNotifierProvider.autoDispose<OrderNotifier, OrderState>(
  (ref) => OrderNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
