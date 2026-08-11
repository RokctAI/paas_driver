import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'on_a_way_orders_state.dart';
import 'on_a_way_orders_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final onAWayOrdersProvider =
    StateNotifierProvider<OnAWayOrdersNotifier, OnAWayOrdersState>(
  (ref) => OnAWayOrdersNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
