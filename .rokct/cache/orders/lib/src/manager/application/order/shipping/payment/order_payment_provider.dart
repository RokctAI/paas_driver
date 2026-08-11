import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_payment_state.dart';
import 'order_payment_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final orderPaymentProvider =
    StateNotifierProvider<OrderPaymentNotifier, OrderPaymentState>(
  (ref) => OrderPaymentNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
