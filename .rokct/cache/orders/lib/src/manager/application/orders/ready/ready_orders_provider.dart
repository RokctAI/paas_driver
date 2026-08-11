import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ready_orders_state.dart';
import 'ready_orders_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final readyOrdersProvider =
    StateNotifierProvider<ReadyOrdersNotifier, ReadyOrdersState>(
  (ref) => ReadyOrdersNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
