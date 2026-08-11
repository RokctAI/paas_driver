import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'new_orders_state.dart';
import 'new_orders_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final newOrdersProvider =
    StateNotifierProvider<NewOrdersNotifier, NewOrdersState>(
  (ref) => NewOrdersNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
