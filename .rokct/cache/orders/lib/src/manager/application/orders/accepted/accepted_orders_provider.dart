import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accepted_orders_state.dart';
import 'accepted_orders_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final acceptedOrdersProvider =
    StateNotifierProvider<AcceptedOrdersNotifier, AcceptedOrdersState>(
  (ref) => AcceptedOrdersNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
