import 'package:flutter/cupertino.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'new_orders_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';

class NewOrdersNotifier extends StateNotifier<NewOrdersState> {
  final SellerOrdersRepositoryFacade _ordersRepository;
  int _page = 0;
  bool _hasMore = true;

  NewOrdersNotifier(this._ordersRepository)
      : super(NewOrdersState(refreshController: RefreshController()));

  Future<void> fetchNewOrders({
    required BuildContext context,
    bool isRefresh = false,
    Function(int)? updateTotal,
    required int activeTabIndex,
  }) async {
    if (isRefresh) {
      _page = 0;
      _hasMore = true;
      if (activeTabIndex == 0) {
        state.refreshController?.requestRefresh();
      }
      state.refreshController?.resetNoData();
    }
    if (!_hasMore) {
      state.refreshController?.loadNoData();
      return;
    }
    if (_page == 0 && !isRefresh) {
      state = state.copyWith(isLoading: true);
    }
    final response = await _ordersRepository.getOrders(
      status: OrderStatus.open,
      page: ++_page,
    );
    response.when(
      success: (data) {
        List<OrderData> orders = isRefresh ? [] : List.from(state.orders);
        final List<OrderData> newOrders = data.data?.orders ?? [];
        orders.addAll(newOrders);
        _hasMore = newOrders.length >= 10;
        if (_page == 1 && !isRefresh) {
          state = state.copyWith(
            isLoading: false,
            orders: orders,
            totalCount: data.data?.statistic?.newOrdersCount ?? 0,
          );
          updateTotal?.call(data.data?.statistic?.newOrdersCount ?? 0);
        } else {
          state = state.copyWith(
            orders: orders,
            totalCount: data.data?.statistic?.newOrdersCount ?? 0,
          );
          updateTotal?.call(data.data?.statistic?.newOrdersCount ?? 0);
        }
        if (isRefresh) {
          state.refreshController?.refreshCompleted();
        } else {
          state.refreshController?.loadComplete();
        }
      },
      failure: (failure,status) {
        _page--;
        if (_page == 0) {
          state = state.copyWith(isLoading: false);
        }
        if (isRefresh) {
          state.refreshController?.refreshFailed();
        } else {
          state.refreshController?.loadFailed();
        }
        if (status == 401) {
          LocalStorage.logout();
          // ADR-005: SDK code never touches the host router directly - the
          // AppRoutes seam (implemented by auth_sdk's app_routes manifest
          // entry) owns the pop-to-login transition.
          AppRoutes.I.replaceLoginRoute(context);
        }
      },
    );
  }
}
