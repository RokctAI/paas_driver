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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:kitchen_sdk/src/manager/application/kitchen/kitchen_state.dart';
import 'package:kitchen_sdk/src/manager/domain/interface/kitchen_orders.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// The manager Kitchen screen's engine — the POS KitchenNotifier
/// (kitchen_notifier.dart) rebuilt on kitchen_sdk's own facade:
///
///  * queue fetch with filter chips + counts + "view more" paging + the
///    debounced order-number search (POS setOrdersQuery, 500ms);
///  * auto-refresh polling on base_sdk's [AppConstants.timeRefresh] (POS
///    _setupRefreshTimer) with the new-order chime on an accepted-count
///    rise (POS kitchen_page.dart:66-75; the fleet carries no audio
///    package, so the chime is the engine's [SystemSound] — orders_sdk's
///    NewOrderChime call);
///  * the dish-line flow: tap advance / double-tap cancel, then the POS's
///    automatic rules — all-cancelled cancels the order, all-done while
///    cooking flips it Ready ([KitchenRules]);
///  * the one-tap order flow: Start cooking (marks every live line
///    preparing, POS _updateAllDetailsToCooking), Mark order ready
///    (guarded on >= 1 done line), confirm-guarded Cancel (cancels every
///    line first, POS _updateAllDetailsToCanceled), and the post-Ready
///    hand-over routing (pickup/dine → delivered, delivery → on the way).
class KitchenNotifier extends StateNotifier<KitchenState> {
  final KitchenOrdersRepositoryFacade _repository;

  /// Injectable chime hook for tests; defaults to the platform alert.
  final void Function() playChime;

  int _page = 0;
  Timer? _refreshTimer;
  Timer? _searchTimer;
  int? _previousAcceptedCount;

  KitchenNotifier(
    this._repository, {
    void Function()? playChime,
  }) : playChime =
           (playChime ?? (() => SystemSound.play(SystemSoundType.alert))),
       super(const KitchenState());

  // ---- queue ----------------------------------------------------------------

  Future<void> fetchOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 0;
    }
    if (_page == 0) {
      state = state.copyWith(isLoading: state.orders.isEmpty);
    }
    final response = await _repository.getKitchenOrders(
      status: state.filter.status,
      search: state.query.isEmpty ? null : state.query,
      page: ++_page,
    );
    response.when(
      success: (data) {
        final orders = isRefresh || _page == 1
            ? data.orders
            : [
                ...state.orders,
                for (final order in data.orders)
                  if (!state.orders.any((o) => o.id == order.id)) order,
              ];
        _registerChime(data.counts[KitchenFilter.accepted]);
        // Keep a stale selection only while its order is still queued.
        final selectionAlive =
            state.selectedId != null &&
            orders.any((o) => o.id == state.selectedId);
        state = state.copyWith(
          isLoading: false,
          orders: orders,
          counts: data.counts,
          total: data.total,
          clearSelection: !selectionAlive,
        );
      },
      failure: (error, statusCode) {
        _page--;
        if (_page <= 0) {
          _page = 0;
          state = state.copyWith(isLoading: false);
        }
        debugPrint('==> fetch kitchen orders fail: $error');
      },
    );
  }

  void _registerChime(int? acceptedCount) {
    final previous = _previousAcceptedCount;
    if (acceptedCount != null) _previousAcceptedCount = acceptedCount;
    if (previous == null || acceptedCount == null) return;
    if (acceptedCount > previous) {
      playChime();
      state = state.copyWith(hasNewActivity: true);
    }
  }

  void selectFilter(KitchenFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter, clearSelection: true);
    fetchOrders(isRefresh: true);
  }

  /// Debounced order-number search (POS setOrdersQuery, 500ms).
  void setQuery(String query) {
    final trimmed = query.trim();
    if (state.query == trimmed) return;
    state = state.copyWith(query: trimmed);
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      fetchOrders(isRefresh: true);
    });
  }

  /// Auto-refresh polling (POS _setupRefreshTimer; base_sdk's shared
  /// 30-second cadence).
  void startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(AppConstants.timeRefresh, (_) {
      fetchOrders(isRefresh: true);
    });
  }

  void stopPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // ---- selection ------------------------------------------------------------

  void selectOrder(String? orderId) {
    if (orderId == null) {
      state = state.copyWith(clearSelection: true);
      return;
    }
    state = state.copyWith(selectedId: orderId);
  }

  /// Wide-screen auto-select (POS auto-select of the first order): keeps
  /// the detail plane filled so the approved 34a never shows a bare
  /// stage. The caller only invokes this on multi-plane widths — on a
  /// phone an auto-selection would push the detail page uninvited.
  void autoSelectFirst() {
    if (state.selectedId != null) return;
    if (state.orders.isEmpty) return;
    state = state.copyWith(selectedId: state.orders.first.id);
  }

  void clearActivity() {
    if (state.hasNewActivity) {
      state = state.copyWith(hasNewActivity: false);
    }
  }

  // ---- dish flow ------------------------------------------------------------

  /// TAP on a dish line: advance it one step, then run the POS's
  /// automatic order rules.
  Future<void> tapDish(KitchenDishData dish) async {
    final next = KitchenRules.tapAdvance(dish.status);
    if (next == null) return;
    await _setDishStatus(dish, next);
  }

  /// DOUBLE-TAP on a dish line: cancel just that dish.
  Future<void> cancelDish(KitchenDishData dish) async {
    if (!KitchenRules.canCancelDish(dish.status)) return;
    await _setDishStatus(dish, DishStatus.canceled);
  }

  Future<void> _setDishStatus(KitchenDishData dish, DishStatus status) async {
    final order = state.selectedOrder;
    if (order?.id == null || dish.id == null || state.isUpdating) return;
    state = state.copyWith(isUpdating: true);
    try {
      final response = await _repository.updateDishStatus(
        orderId: order!.id!,
        dishId: dish.id!,
        status: status,
      );
      await response.when(
        success: (_) async {
          _patchSelectedOrder(
            order.copyWith(
              dishes: [
                for (final d in order.dishes)
                  if (d.id == dish.id) d.copyWith(prepStatus: status) else d,
              ],
            ),
          );
          await _applyAutoRules();
        },
        failure: (error, statusCode) async {
          debugPrint('==> update dish status fail: $error');
        },
      );
    } finally {
      state = state.copyWith(isUpdating: false);
    }
  }

  void _patchSelectedOrder(KitchenOrderData updated) {
    state = state.copyWith(
      orders: [
        for (final o in state.orders)
          if (o.id == updated.id) updated else o,
      ],
    );
  }

  /// The POS's automatic rules after any dish change
  /// (kitchen_notifier.dart _checkAndUpdateOrderStatus).
  Future<void> _applyAutoRules() async {
    final order = state.selectedOrder;
    if (order == null) return;
    final dishes = order.dishStatuses;
    if (KitchenRules.allDishesCanceled(dishes) &&
        order.status != KitchenStatus.canceled) {
      await _changeOrderStatus(order, KitchenStatus.canceled.wire);
      return;
    }
    if (KitchenRules.shouldAutoReady(
      orderStatus: order.status,
      dishes: dishes,
    )) {
      await _changeOrderStatus(order, KitchenStatus.ready.wire);
    }
  }

  // ---- order flow -----------------------------------------------------------

  /// Accepted → Cooking ("Start cooking"): the order starts cooking and
  /// every live dish line moves to Preparing (POS
  /// _updateAllDetailsToCooking).
  Future<void> startCooking() async {
    final order = state.selectedOrder;
    if (order?.id == null || order!.status != KitchenStatus.accepted) return;
    for (final dish in order.dishes) {
      if (dish.id != null &&
          dish.status != DishStatus.canceled &&
          dish.status != DishStatus.done) {
        await _repository.updateDishStatus(
          orderId: order.id!,
          dishId: dish.id!,
          status: DishStatus.preparing,
        );
      }
    }
    await _changeOrderStatus(
      order.copyWith(
        dishes: [
          for (final d in order.dishes)
            if (d.status != DishStatus.canceled && d.status != DishStatus.done)
              d.copyWith(prepStatus: DishStatus.preparing)
            else
              d,
        ],
      ),
      KitchenStatus.cooking.wire,
    );
  }

  /// Cooking → Ready ("Mark order ready"), guarded on at least one done
  /// dish (POS kitchen_notifier.dart:353-364).
  Future<void> markReady() async {
    final order = state.selectedOrder;
    if (order == null || order.status != KitchenStatus.cooking) return;
    if (!KitchenRules.canMarkReady(order.dishStatuses)) return;
    await _changeOrderStatus(order, KitchenStatus.ready.wire);
  }

  /// The post-Ready hand-over (POS kitchen_notifier.dart:100-116):
  /// pickup/dine-in → delivered, delivery → on the way. The order leaves
  /// the kitchen queue on the next refresh.
  Future<void> handOver() async {
    final order = state.selectedOrder;
    if (order == null || order.status != KitchenStatus.ready) return;
    await _changeOrderStatus(
      order,
      KitchenRules.postReadyRouteWire(order.deliveryType),
      refreshAfter: true,
    );
  }

  /// Confirm-guarded cancel (the confirm dialog lives in the widget):
  /// every line is cancelled first, then the order (POS
  /// _updateAllDetailsToCanceled + changeStatus).
  Future<void> cancelOrder() async {
    final order = state.selectedOrder;
    if (order?.id == null || order!.status == KitchenStatus.canceled) return;
    for (final dish in order.dishes) {
      if (dish.id != null && dish.status != DishStatus.canceled) {
        await _repository.updateDishStatus(
          orderId: order.id!,
          dishId: dish.id!,
          status: DishStatus.canceled,
        );
      }
    }
    await _changeOrderStatus(
      order.copyWith(
        dishes: [
          for (final d in order.dishes) d.copyWith(prepStatus: DishStatus.canceled),
        ],
      ),
      KitchenStatus.canceled.wire,
    );
  }

  Future<void> _changeOrderStatus(
    KitchenOrderData order,
    String wireStatus, {
    bool refreshAfter = false,
  }) async {
    if (order.id == null) return;
    final response = await _repository.updateOrderStatus(
      orderId: order.id!,
      wireStatus: wireStatus,
    );
    response.when(
      success: (_) {
        final kitchenStatus = KitchenStatus.fromWire(wireStatus);
        _patchSelectedOrder(
          kitchenStatus == null
              ? order
              : order.copyWith(status: kitchenStatus),
        );
      },
      failure: (error, statusCode) {
        debugPrint('==> update kitchen order status fail: $error');
      },
    );
    if (refreshAfter) {
      await fetchOrders(isRefresh: true);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchTimer?.cancel();
    super.dispose();
  }
}
