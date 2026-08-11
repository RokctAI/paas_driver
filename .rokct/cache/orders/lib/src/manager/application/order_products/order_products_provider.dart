import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_products_state.dart';
import 'order_products_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';

final orderProductsProvider =
    StateNotifierProvider<OrderProductsNotifier, OrderProductsState>(
  (ref) => OrderProductsNotifier(GetIt.instance<PosProductsRepositoryFacade>()),
);
