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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cooking_orders_state.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';

/// The cooking queue — the seventh column the approved board ("31b adopt
/// 31a", frames 33a/33b) restores from the POS's state machine. base_sdk's
/// `OrderStatus` has no `cooking` member, so this queue fetches by raw wire
/// status through the facade's [SellerOrdersRepositoryFacade.getOrders]
/// `rawStatus` seam. Mirrors ReadyOrdersNotifier otherwise.
class CookingOrdersNotifier extends StateNotifier<CookingOrdersState> {
  final SellerOrdersRepositoryFacade _ordersRepository;
  int _page = 0;
  bool _hasMore = true;

  CookingOrdersNotifier(this._ordersRepository)
    : super(const CookingOrdersState());

  Future<void> fetchCookingOrders({
    bool isRefresh = false,
    Function(int)? updateTotal,
    String? from,
    String? to,
  }) async {
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
      rawStatus: BoardStatus.cooking.wire,
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
        // Backend statistic block may not carry cooking_orders_count yet —
        // fall back to what is loaded so the pill never reads 0 over a
        // populated column.
        final int total =
            data.data?.statistic?.cookingOrdersCount ?? orders.length;
        state = state.copyWith(
          isLoading: false,
          orders: orders,
          totalCount: total,
        );
        updateTotal?.call(total);
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
