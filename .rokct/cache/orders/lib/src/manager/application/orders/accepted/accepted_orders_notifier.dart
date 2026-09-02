// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accepted_orders_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/services/enums.dart';

class AcceptedOrdersNotifier extends StateNotifier<AcceptedOrdersState> {
  final SellerOrdersRepositoryFacade _ordersRepository;
  int _page = 0;
  bool _hasMore = true;

  AcceptedOrdersNotifier(this._ordersRepository)
      : super(const AcceptedOrdersState());

  Future<void> fetchAcceptedOrders({
    RefreshController? refreshController,
    bool isRefresh = false,
    Function(int)? updateTotal,
    String? from,
    String? to,
  }) async {
    if (isRefresh) {
      _page = 0;
      _hasMore = true;
      refreshController?.requestRefresh();
    }
    if (!_hasMore) {
      refreshController?.loadNoData();
      return;
    }
    if (_page == 0 && !isRefresh) {
      state = state.copyWith(isLoading: true);
    }
    final response = await _ordersRepository.getOrders(
      status: OrderStatus.accepted,
      page: ++_page,
      from: from,
      to: to,
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
            totalCount: data.data?.statistic?.acceptedOrdersCount ?? 0,
          );
          updateTotal?.call(data.data?.statistic?.acceptedOrdersCount ?? 0);
        } else {
          state = state.copyWith(
            orders: orders,
            totalCount: data.data?.statistic?.acceptedOrdersCount ?? 0,
          );
          updateTotal?.call(data.data?.statistic?.acceptedOrdersCount ?? 0);
        }
        if (isRefresh) {
          refreshController?.refreshCompleted();
        } else {
          refreshController?.loadComplete();
        }
      },
      failure: (failure,status) {
        _page--;
        if (_page == 0) {
          state = state.copyWith(isLoading: false);
        }
        if (isRefresh) {
          refreshController?.refreshFailed();
        } else {
          refreshController?.loadFailed();
        }
      },
    );
  }
}
