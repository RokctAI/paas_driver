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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:kitchen_sdk/src/manager/domain/interface/kitchen_orders.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/response/kitchen_orders_response.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// Demo-only [KitchenOrdersRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// serves a fictional kitchen queue from memory, so the manager Kitchen tab
/// shows a live board — ticking clocks, dish pills, filter counts — instead
/// of its "no orders" empty state in demo builds. Selected in place of
/// [KitchenOrdersRepository] by `ManagerKitchenDependencies`, the same
/// `AppConstants.isDemo` split merchants_sdk's POS seams and products_sdk's
/// catalog facades already apply (zones_sdk's
/// `DemoDriverDeliveryZonesRepository` precedent).
///
/// Never used in production: no HTTP client is constructed, every write
/// mutates the in-memory queue and nothing leaves the device.
///
/// The dishes are deliberately the ones orders_sdk's
/// `DemoSellerOrdersRepository` seeds onto the order board, so the queue and
/// the kitchen tell one coherent story. Duplicated rather than imported:
/// kitchen_sdk must not depend on orders_sdk (ADR-005), and a handful of
/// dish names is cheaper than a new seam.
///
/// Session-local by design: status moves made during a tour stick for the
/// rest of the process and reset on the next launch. Nothing is persisted.
class DemoKitchenOrdersRepository implements KitchenOrdersRepositoryFacade {
  /// Wall-clock anchor, resolved once per launch so the cards' flip clocks
  /// read as minutes-old whenever the tour runs.
  static final DateTime _now = DateTime.now();

  static KitchenDishData _dish(
    String id,
    String title,
    int quantity,
    DishStatus status,
  ) =>
      KitchenDishData(
        id: id,
        title: title,
        quantity: quantity,
        prepStatus: status,
      );

  /// The seeded service: five tickets across the three live columns, with
  /// dish lines at mixed prep states so the pills and the "n of m done"
  /// line both render something.
  static List<KitchenOrderData> _seed() => <KitchenOrderData>[
        KitchenOrderData(
          id: 'DEMO-1041',
          status: KitchenStatus.accepted,
          deliveryType: 'delivery',
          note: 'No chilli on the second wrap, please.',
          createdAt: _now.subtract(const Duration(minutes: 3)),
          updatedAt: _now.subtract(const Duration(minutes: 3)),
          dishes: <KitchenDishData>[
            _dish('1', 'Peri-peri chicken wrap', 2, DishStatus.pending),
            _dish('2', 'Chakalaka fries', 1, DishStatus.pending),
          ],
        ),
        KitchenOrderData(
          id: 'DEMO-1040',
          status: KitchenStatus.accepted,
          deliveryType: 'dine_in',
          createdAt: _now.subtract(const Duration(minutes: 8)),
          updatedAt: _now.subtract(const Duration(minutes: 8)),
          dishes: <KitchenDishData>[
            _dish('3', 'Bunny chow (quarter)', 2, DishStatus.pending),
          ],
        ),
        KitchenOrderData(
          id: 'DEMO-1039',
          status: KitchenStatus.cooking,
          deliveryType: 'pickup',
          createdAt: _now.subtract(const Duration(minutes: 14)),
          updatedAt: _now.subtract(const Duration(minutes: 6)),
          dishes: <KitchenDishData>[
            _dish('4', 'Boerewors roll', 2, DishStatus.preparing),
          ],
        ),
        KitchenOrderData(
          id: 'DEMO-1038',
          status: KitchenStatus.cooking,
          deliveryType: 'delivery',
          note: 'Table by the window — running late.',
          createdAt: _now.subtract(const Duration(minutes: 21)),
          updatedAt: _now.subtract(const Duration(minutes: 4)),
          dishes: <KitchenDishData>[
            _dish('5', 'Family braai platter', 1, DishStatus.preparing),
            _dish('6', 'Chakalaka fries', 2, DishStatus.done),
          ],
        ),
        KitchenOrderData(
          id: 'DEMO-1037',
          status: KitchenStatus.ready,
          deliveryType: 'delivery',
          createdAt: _now.subtract(const Duration(minutes: 29)),
          updatedAt: _now.subtract(const Duration(minutes: 2)),
          dishes: <KitchenDishData>[
            _dish('7', 'Gatsby (half)', 2, DishStatus.done),
          ],
        ),
      ];

  /// Session-local overlay: seeded lazily on first read, then mutated in
  /// place by the status writes below.
  static List<KitchenOrderData>? _orders;

  static List<KitchenOrderData> get _all => _orders ??= _seed();

  /// Drops the overlay so the next read re-seeds; used by tests.
  static void reset() => _orders = null;

  static Map<KitchenFilter, int> _counts() {
    final Map<KitchenFilter, int> counts = <KitchenFilter, int>{
      KitchenFilter.all: _all.length,
    };
    for (final KitchenFilter filter in KitchenFilter.values) {
      if (filter == KitchenFilter.all) continue;
      counts[filter] = _all
          .where((KitchenOrderData order) => order.status == filter.status)
          .length;
    }
    return counts;
  }

  @override
  Future<ApiResult<KitchenOrdersResponse>> getKitchenOrders({
    KitchenStatus? status,
    String? search,
    int? page,
  }) async {
    Iterable<KitchenOrderData> rows = _all;
    if (status != null) {
      rows = rows.where((KitchenOrderData order) => order.status == status);
    }
    if (search != null && search.trim().isNotEmpty) {
      final String needle = search.trim().toLowerCase();
      rows = rows.where(
        (KitchenOrderData order) =>
            (order.id ?? '').toLowerCase().contains(needle),
      );
    }
    final List<KitchenOrderData> matched = rows.toList();
    // The whole seed fits on page 1, so later pages come back empty and the
    // "view more" affordance never asks for a page that does not exist.
    final List<KitchenOrderData> served =
        (page ?? 1) > 1 ? const <KitchenOrderData>[] : matched;
    return ApiResult<KitchenOrdersResponse>.success(
      data: KitchenOrdersResponse(
        orders: served,
        counts: _counts(),
        total: matched.length,
      ),
    );
  }

  @override
  Future<ApiResult<void>> updateOrderStatus({
    required String orderId,
    required String wireStatus,
  }) async {
    final KitchenStatus? next = KitchenStatus.fromWire(wireStatus);
    for (int i = 0; i < _all.length; i++) {
      if (_all[i].id != orderId) continue;
      if (next == null) {
        // 'on_a_way' / 'delivered' — the hand-over leaves the kitchen
        // vocabulary, so the ticket leaves the queue, exactly as a real
        // refetch would drop it.
        _all.removeAt(i);
      } else {
        _all[i] = _all[i].copyWith(status: next);
      }
      break;
    }
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<void>> updateDishStatus({
    required String orderId,
    required String dishId,
    required DishStatus status,
  }) async {
    for (int i = 0; i < _all.length; i++) {
      if (_all[i].id != orderId) continue;
      _all[i] = _all[i].copyWith(
        dishes: <KitchenDishData>[
          for (final KitchenDishData dish in _all[i].dishes)
            if (dish.id == dishId)
              KitchenDishData(
                id: dish.id,
                title: dish.title,
                quantity: dish.quantity,
                prepStatus: status,
              )
            else
              dish,
        ],
      );
      break;
    }
    return const ApiResult.success(data: null);
  }
}
