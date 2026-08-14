import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'canceled_orders_state.dart';
import 'canceled_orders_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final canceledOrdersProvider =
    StateNotifierProvider<CanceledOrdersNotifier, CanceledOrdersState>(
  (ref) =>
      CanceledOrdersNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
