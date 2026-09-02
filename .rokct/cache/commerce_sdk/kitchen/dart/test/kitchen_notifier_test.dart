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
//
// The kitchen notifier against a fake facade: filter chips + counts, the
// dish tap/double-tap flow with the POS's automatic rules, the one-tap
// order flow (start cooking / mark ready / hand over / cancel) and the
// new-order chime.

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sdk/src/manager/application/kitchen/kitchen_notifier.dart';
import 'package:kitchen_sdk/src/manager/domain/interface/kitchen_orders.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/response/kitchen_orders_response.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

class _FakeKitchenRepo implements KitchenOrdersRepositoryFacade {
  KitchenOrdersResponse response = const KitchenOrdersResponse();

  final List<KitchenStatus?> queueRequests = [];
  final List<String?> searchRequests = [];
  final List<(String orderId, String wire)> orderStatusCalls = [];
  final List<(String orderId, String dishId, DishStatus status)> dishCalls =
      [];

  @override
  Future<ApiResult<KitchenOrdersResponse>> getKitchenOrders({
    KitchenStatus? status,
    String? search,
    int? page,
  }) async {
    queueRequests.add(status);
    searchRequests.add(search);
    return ApiResult.success(data: response);
  }

  @override
  Future<ApiResult<void>> updateOrderStatus({
    required String orderId,
    required String wireStatus,
  }) async {
    orderStatusCalls.add((orderId, wireStatus));
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<void>> updateDishStatus({
    required String orderId,
    required String dishId,
    required DishStatus status,
  }) async {
    dishCalls.add((orderId, dishId, status));
    return const ApiResult.success(data: null);
  }
}

KitchenOrderData _order({
  String id = 'ord-1',
  KitchenStatus status = KitchenStatus.cooking,
  String deliveryType = 'delivery',
  List<KitchenDishData> dishes = const [],
}) => KitchenOrderData(
  id: id,
  status: status,
  deliveryType: deliveryType,
  createdAt: DateTime(2026, 8, 29, 11, 58),
  updatedAt: DateTime(2026, 8, 29, 12, 30),
  dishes: dishes,
);

void main() {
  late _FakeKitchenRepo repo;
  late KitchenNotifier notifier;
  late int chimes;

  setUp(() {
    repo = _FakeKitchenRepo();
    chimes = 0;
    notifier = KitchenNotifier(repo, playChime: () => chimes++);
  });

  tearDown(() => notifier.dispose());

  group('queue + filter chips', () {
    test('fetch fills orders, counts and total', () async {
      repo.response = KitchenOrdersResponse(
        orders: [_order()],
        counts: const {
          KitchenFilter.all: 12,
          KitchenFilter.accepted: 2,
          KitchenFilter.cooking: 6,
          KitchenFilter.ready: 3,
          KitchenFilter.canceled: 1,
        },
        total: 12,
      );
      await notifier.fetchOrders(isRefresh: true);
      expect(notifier.state.orders, hasLength(1));
      expect(notifier.state.countOf(KitchenFilter.all), 12);
      expect(notifier.state.countOf(KitchenFilter.cooking), 6);
      expect(notifier.state.total, 12);
      expect(notifier.state.moreCount, 11);
      // The All chip queries with no status.
      expect(repo.queueRequests, [null]);
    });

    test('selectFilter refetches with that chip\'s wire status and drops the '
        'selection', () async {
      repo.response = KitchenOrdersResponse(orders: [_order()]);
      await notifier.fetchOrders(isRefresh: true);
      notifier.selectOrder('ord-1');
      expect(notifier.state.selectedId, 'ord-1');

      notifier.selectFilter(KitchenFilter.ready);
      await Future<void>.delayed(Duration.zero);
      expect(repo.queueRequests.last, KitchenStatus.ready);
      expect(notifier.state.filter, KitchenFilter.ready);
    });

    test('auto-select fills the empty selection with the first order '
        '(the 34a no-bare-stage rule), never steals an existing one',
        () async {
      repo.response = KitchenOrdersResponse(
        orders: [_order(id: 'ord-1'), _order(id: 'ord-2')],
      );
      await notifier.fetchOrders(isRefresh: true);
      notifier.autoSelectFirst();
      expect(notifier.state.selectedId, 'ord-1');
      notifier.selectOrder('ord-2');
      notifier.autoSelectFirst();
      expect(notifier.state.selectedId, 'ord-2');
    });
  });

  group('new-order chime (POS kitchen_page.dart:66-75)', () {
    test('first observation baselines silently; a rise chimes and lights '
        'the bell dot', () async {
      repo.response = const KitchenOrdersResponse(
        counts: {KitchenFilter.accepted: 2},
      );
      await notifier.fetchOrders(isRefresh: true);
      expect(chimes, 0);
      expect(notifier.state.hasNewActivity, isFalse);

      repo.response = const KitchenOrdersResponse(
        counts: {KitchenFilter.accepted: 3},
      );
      await notifier.fetchOrders(isRefresh: true);
      expect(chimes, 1);
      expect(notifier.state.hasNewActivity, isTrue);

      notifier.clearActivity();
      expect(notifier.state.hasNewActivity, isFalse);

      // A fall never chimes.
      repo.response = const KitchenOrdersResponse(
        counts: {KitchenFilter.accepted: 1},
      );
      await notifier.fetchOrders(isRefresh: true);
      expect(chimes, 1);
    });
  });

  group('dish flow + automatic rules', () {
    test('tap advances a pending line to preparing', () async {
      repo.response = KitchenOrdersResponse(
        orders: [
          _order(
            dishes: const [
              KitchenDishData(id: 'd1', prepStatus: DishStatus.pending),
              KitchenDishData(id: 'd2', prepStatus: DishStatus.preparing),
            ],
          ),
        ],
      );
      await notifier.fetchOrders(isRefresh: true);
      notifier.selectOrder('ord-1');

      await notifier.tapDish(notifier.state.selectedOrder!.dishes.first);
      expect(repo.dishCalls, [('ord-1', 'd1', DishStatus.preparing)]);
      expect(
        notifier.state.selectedOrder!.dishes.first.status,
        DishStatus.preparing,
      );
      // Lines still live — no automatic order transition.
      expect(repo.orderStatusCalls, isEmpty);
    });

    test('the last line reaching done while cooking auto-flips the order '
        'Ready', () async {
      repo.response = KitchenOrdersResponse(
        orders: [
          _order(
            dishes: const [
              KitchenDishData(id: 'd1', prepStatus: DishStatus.done),
              KitchenDishData(id: 'd2', prepStatus: DishStatus.preparing),
            ],
          ),
        ],
      );
      await notifier.fetchOrders(isRefresh: true);
      notifier.selectOrder('ord-1');

      await notifier.tapDish(notifier.state.selectedOrder!.dishes.last);
      expect(repo.dishCalls.last, ('ord-1', 'd2', DishStatus.done));
      expect(repo.orderStatusCalls, [('ord-1', 'ready')]);
      expect(notifier.state.selectedOrder!.status, KitchenStatus.ready);
    });

    test('double-tap cancelling the last live line auto-cancels the order',
        () async {
      repo.response = KitchenOrdersResponse(
        orders: [
          _order(
            dishes: const [
              KitchenDishData(id: 'd1', prepStatus: DishStatus.canceled),
              KitchenDishData(id: 'd2', prepStatus: DishStatus.preparing),
            ],
          ),
        ],
      );
      await notifier.fetchOrders(isRefresh: true);
      notifier.selectOrder('ord-1');

      await notifier.cancelDish(notifier.state.selectedOrder!.dishes.last);
      expect(repo.dishCalls.last, ('ord-1', 'd2', DishStatus.canceled));
      expect(repo.orderStatusCalls, [('ord-1', 'canceled')]);
      expect(notifier.state.selectedOrder!.status, KitchenStatus.canceled);
    });

    test('a cancelled line is inert to taps', () async {
      repo.response = KitchenOrdersResponse(
        orders: [
          _order(
            dishes: const [
              KitchenDishData(id: 'd1', prepStatus: DishStatus.canceled),
            ],
          ),
        ],
      );
      await notifier.fetchOrders(isRefresh: true);
      notifier.selectOrder('ord-1');
      await notifier.tapDish(notifier.state.selectedOrder!.dishes.first);
      await notifier.cancelDish(notifier.state.selectedOrder!.dishes.first);
      expect(repo.dishCalls, isEmpty);
    });
  });

  group('one-tap order flow', () {
    test('start cooking marks every live line preparing, then the order '
        'cooking', () async {
      repo.response = KitchenOrdersResponse(
        orders: [
          _order(
            status: KitchenStatus.accepted,
            dishes: const [
              KitchenDishData(id: 'd1', prepStatus: DishStatus.pending),
              KitchenDishData(id: 'd2', prepStatus: DishStatus.canceled),
            ],
          ),
        ],
      );
      await notifier.fetchOrders(isRefresh: true);
      notifier.selectOrder('ord-1');

      await notifier.startCooking();
      // The cancelled line is skipped (POS _updateAllDetailsToCooking).
      expect(repo.dishCalls, [('ord-1', 'd1', DishStatus.preparing)]);
      expect(repo.orderStatusCalls, [('ord-1', 'cooking')]);
      expect(notifier.state.selectedOrder!.status, KitchenStatus.cooking);
    });

    test('mark ready is guarded: no done dish, no call', () async {
      repo.response = KitchenOrdersResponse(
        orders: [
          _order(
            dishes: const [
              KitchenDishData(id: 'd1', prepStatus: DishStatus.preparing),
            ],
          ),
        ],
      );
      await notifier.fetchOrders(isRefresh: true);
      notifier.selectOrder('ord-1');
      await notifier.markReady();
      expect(repo.orderStatusCalls, isEmpty);
    });

    test('hand over routes a READY delivery order on its way, a pickup to '
        'delivered', () async {
      repo.response = KitchenOrdersResponse(
        orders: [
          _order(id: 'ord-1', status: KitchenStatus.ready),
          _order(
            id: 'ord-2',
            status: KitchenStatus.ready,
            deliveryType: 'pickup',
          ),
        ],
      );
      await notifier.fetchOrders(isRefresh: true);

      notifier.selectOrder('ord-1');
      await notifier.handOver();
      expect(repo.orderStatusCalls.last, ('ord-1', 'on_a_way'));

      notifier.selectOrder('ord-2');
      await notifier.handOver();
      expect(repo.orderStatusCalls.last, ('ord-2', 'delivered'));
    });

    test('cancel order cancels every live line first, then the order (the '
        'dialog guard lives in the widget)', () async {
      repo.response = KitchenOrdersResponse(
        orders: [
          _order(
            dishes: const [
              KitchenDishData(id: 'd1', prepStatus: DishStatus.done),
              KitchenDishData(id: 'd2', prepStatus: DishStatus.canceled),
            ],
          ),
        ],
      );
      await notifier.fetchOrders(isRefresh: true);
      notifier.selectOrder('ord-1');

      await notifier.cancelOrder();
      expect(repo.dishCalls, [('ord-1', 'd1', DishStatus.canceled)]);
      expect(repo.orderStatusCalls, [('ord-1', 'canceled')]);
      expect(notifier.state.selectedOrder!.status, KitchenStatus.canceled);
    });
  });

  group('search', () {
    test('setQuery debounces, then refetches with the query', () async {
      repo.response = const KitchenOrdersResponse();
      await notifier.fetchOrders(isRefresh: true);
      notifier.setQuery('1043');
      // Not yet — the POS's 500ms debounce.
      expect(repo.searchRequests.where((q) => q == '1043'), isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(repo.searchRequests.last, '1043');
    });
  });
}
