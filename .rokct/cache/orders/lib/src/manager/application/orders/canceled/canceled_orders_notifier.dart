import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'canceled_orders_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/services/enums.dart';

/// Canceled queue for the wide-screen order board (the POS
/// `canceledOrdersProvider` analog). Same shape as [DeliveredOrdersNotifier]:
/// board-only, so no RefreshController — pagination is scroll-driven.
class CanceledOrdersNotifier extends StateNotifier<CanceledOrdersState> {
  final SellerOrdersRepositoryFacade _ordersRepository;
  int _page = 0;
  bool _hasMore = true;

  CanceledOrdersNotifier(this._ordersRepository)
      : super(const CanceledOrdersState());

  Future<void> fetchCanceledOrders({bool isRefresh = false}) async {
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
      status: OrderStatus.canceled,
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
          totalCount: data.data?.statistic?.cancelOrdersCount ?? 0,
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
