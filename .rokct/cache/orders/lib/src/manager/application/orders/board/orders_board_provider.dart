import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'orders_board_state.dart';
import 'orders_board_notifier.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

final ordersBoardProvider =
    StateNotifierProvider<OrdersBoardNotifier, OrdersBoardState>(
  (ref) => OrdersBoardNotifier(GetIt.instance<SellerOrdersRepositoryFacade>()),
);
