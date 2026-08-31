// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter/cupertino.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'new_orders_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/infrastructure/services/manager_orders_local_store.dart';
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
    String? from,
    String? to,
  }) async {
    if (isRefresh) {
      _page = 0;
      _hasMore = true;
      // position guard: on the wide-screen board no SmartRefresher is built,
      // so the controller is unattached and requestRefresh() would throw.
      // Board callers also pass activeTabIndex -1 for the same reason.
      if (activeTabIndex == 0 && state.refreshController?.position != null) {
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
      from: from,
      to: to,
    );
    await response.when(
      success: (data) async {
        List<OrderData> orders = isRefresh ? [] : List.from(state.orders);
        final List<OrderData> newOrders = data.data?.orders ?? [];
        orders.addAll(newOrders);
        if (_page == 1) {
          // Prepend local not-yet-synced POS sales (pendingSync rows from
          // the manager_orders box) so an offline sale is visible in the
          // queue immediately.
          final pending = await ManagerOrdersLocalStore.unsyncedAsOrders();
          if (pending.isNotEmpty) orders = [...pending, ...newOrders];
        }
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
      failure: (failure, status) async {
        _page--;
        if (_page == 0) {
          // Backend unreachable: still surface local not-yet-synced sales.
          final pending = await ManagerOrdersLocalStore.unsyncedAsOrders();
          state = pending.isEmpty
              ? state.copyWith(isLoading: false)
              : state.copyWith(isLoading: false, orders: pending);
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
