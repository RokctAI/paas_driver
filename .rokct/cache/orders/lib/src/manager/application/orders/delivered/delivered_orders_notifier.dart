import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

import 'delivered_orders_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/services/enums.dart';

/// Delivered queue for the wide-screen order board (the POS
/// `deliveredOrdersProvider` analog). The phone tab bar only shows the four
/// active queues, so unlike its siblings this state carries no
/// RefreshController — the board paginates by scroll position instead of
/// pull-to-refresh.
class DeliveredOrdersNotifier extends StateNotifier<DeliveredOrdersState> {
  final SellerOrdersRepositoryFacade _ordersRepository;
  int _page = 0;
  bool _hasMore = true;

  DeliveredOrdersNotifier(this._ordersRepository)
      : super(const DeliveredOrdersState());

  Future<void> fetchDeliveredOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 0;
      _hasMore = true;
    }
    if (!_hasMore) {
      return;
    }
    if (_page == 0 && !isRefresh) {
      state = state.copyWith(isLoading: true);
    }
    final response = await _ordersRepository.getOrders(
      status: OrderStatus.delivered,
      page: ++_page,
    );
    response.when(
      success: (data) {
        List<OrderData> orders = isRefresh ? [] : List.from(state.orders);
        final List<OrderData> newOrders = data.data?.orders ?? [];
        orders.addAll(newOrders);
        _hasMore = newOrders.length >= 10;
        state = state.copyWith(
          isLoading: false,
          orders: orders,
          totalCount: data.data?.statistic?.deliveredOrdersCount ?? 0,
        );
      },
      failure: (failure, status) {
        _page--;
        if (_page == 0) {
          state = state.copyWith(isLoading: false);
        }
      },
    );
  }
}
