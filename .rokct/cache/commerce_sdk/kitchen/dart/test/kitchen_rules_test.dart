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
// The kitchen's pure state machine — the POS KitchenNotifier rules
// (approved 34d: tap advance / double-tap cancel and the three automatic
// rules) plus the wire mappings and the queue response parsing.

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/response/kitchen_orders_response.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

void main() {
  group('DishStatus tap cycle (34d: Pending -> Preparing -> Done)', () {
    test('tap advances one step', () {
      expect(KitchenRules.tapAdvance(DishStatus.pending), DishStatus.preparing);
      expect(KitchenRules.tapAdvance(DishStatus.preparing), DishStatus.done);
    });

    test('done and cancelled lines do not advance', () {
      expect(KitchenRules.tapAdvance(DishStatus.done), isNull);
      expect(KitchenRules.tapAdvance(DishStatus.canceled), isNull);
    });

    test('double-tap cancels from any live state, cancelled is inert', () {
      expect(KitchenRules.canCancelDish(DishStatus.pending), isTrue);
      expect(KitchenRules.canCancelDish(DishStatus.preparing), isTrue);
      expect(KitchenRules.canCancelDish(DishStatus.done), isTrue);
      expect(KitchenRules.canCancelDish(DishStatus.canceled), isFalse);
    });
  });

  group('automatic order rules (POS kitchen_notifier.dart)', () {
    test('all dishes cancelled -> order auto-cancels; empty never does', () {
      expect(
        KitchenRules.allDishesCanceled(
          [DishStatus.canceled, DishStatus.canceled],
        ),
        isTrue,
      );
      expect(
        KitchenRules.allDishesCanceled(
          [DishStatus.canceled, DishStatus.pending],
        ),
        isFalse,
      );
      expect(KitchenRules.allDishesCanceled([]), isFalse);
    });

    test('all dishes done while cooking -> auto-Ready', () {
      expect(
        KitchenRules.shouldAutoReady(
          orderStatus: KitchenStatus.cooking,
          dishes: [DishStatus.done, DishStatus.done],
        ),
        isTrue,
      );
    });

    test('done + cancelled mix (>= 1 done) still auto-Readies', () {
      expect(
        KitchenRules.shouldAutoReady(
          orderStatus: KitchenStatus.cooking,
          dishes: [DishStatus.done, DishStatus.canceled],
        ),
        isTrue,
      );
    });

    test('a pending or preparing line blocks auto-Ready', () {
      expect(
        KitchenRules.shouldAutoReady(
          orderStatus: KitchenStatus.cooking,
          dishes: [DishStatus.done, DishStatus.preparing],
        ),
        isFalse,
      );
      expect(
        KitchenRules.shouldAutoReady(
          orderStatus: KitchenStatus.cooking,
          dishes: [DishStatus.done, DishStatus.pending],
        ),
        isFalse,
      );
    });

    test('only a COOKING order auto-Readies (all-cancelled wins instead)', () {
      expect(
        KitchenRules.shouldAutoReady(
          orderStatus: KitchenStatus.accepted,
          dishes: [DishStatus.done],
        ),
        isFalse,
      );
      expect(
        KitchenRules.shouldAutoReady(
          orderStatus: KitchenStatus.cooking,
          dishes: [DishStatus.canceled, DishStatus.canceled],
        ),
        isFalse,
      );
    });

    test('ready guard: >= 1 done dish arms "Mark order ready"', () {
      expect(KitchenRules.canMarkReady([DishStatus.done]), isTrue);
      expect(
        KitchenRules.canMarkReady([DishStatus.preparing, DishStatus.pending]),
        isFalse,
      );
      expect(KitchenRules.canMarkReady([]), isFalse);
    });

    test('post-Ready routing: pickup/dine -> delivered, delivery -> on a way',
        () {
      expect(KitchenRules.postReadyRouteWire('delivery'), 'on_a_way');
      expect(KitchenRules.postReadyRouteWire('dine_in'), 'delivered');
      expect(KitchenRules.postReadyRouteWire('pickup'), 'delivered');
      expect(KitchenRules.postReadyRouteWire(null), 'delivered');
    });
  });

  group('wire mappings', () {
    test('KitchenStatus tolerates DB capitalization and both cancel spellings',
        () {
      expect(KitchenStatus.fromWire('Accepted'), KitchenStatus.accepted);
      expect(KitchenStatus.fromWire('cooking'), KitchenStatus.cooking);
      expect(KitchenStatus.fromWire('Cancelled'), KitchenStatus.canceled);
      expect(KitchenStatus.fromWire('canceled'), KitchenStatus.canceled);
      expect(KitchenStatus.fromWire('delivered'), isNull);
      expect(KitchenStatus.fromWire(null), isNull);
    });

    test('DishStatus wire round-trip and POS aliases', () {
      expect(DishStatus.fromWire('New'), DishStatus.pending);
      expect(DishStatus.fromWire('accepted'), DishStatus.pending);
      expect(DishStatus.fromWire('Cooking'), DishStatus.preparing);
      expect(DishStatus.fromWire('ready'), DishStatus.done);
      expect(DishStatus.fromWire('ended'), DishStatus.done);
      expect(DishStatus.fromWire('Cancelled'), DishStatus.canceled);
      for (final status in DishStatus.values) {
        expect(DishStatus.fromWire(status.wire), status);
      }
    });
  });

  group('queue response parsing (filter counts)', () {
    test('orders, chip counts and total parse; unmigrated prep_status reads '
        'pending', () {
      final response = KitchenOrdersResponse.fromJson({
        'orders': [
          {
            'name': 'a1b2c3d4e5',
            'status': 'Cooking',
            'creation': '2026-08-29 11:58:00',
            'modified': '2026-08-29 12:30:00',
            'delivery_type': 'delivery',
            'note': 'No onions — allergy.',
            'items': [
              {
                'name': 'row1',
                'title': 'Beef Kota',
                'quantity': 2,
                'prep_status': 'Ready',
              },
              {'name': 'row2', 'title': 'Chips', 'quantity': 1},
            ],
          },
        ],
        'counts': {
          'all': 12,
          'accepted': 2,
          'cooking': 6,
          'ready': 3,
          'canceled': 1,
        },
        'total': 12,
      });

      expect(response.orders, hasLength(1));
      final order = response.orders.first;
      expect(order.id, 'a1b2c3d4e5');
      expect(order.status, KitchenStatus.cooking);
      expect(order.dishes, hasLength(2));
      expect(order.dishes.first.status, DishStatus.done);
      // No prep_status on the wire (unmigrated site) -> pending.
      expect(order.dishes.last.status, DishStatus.pending);
      expect(order.dishStatuses, [DishStatus.done, DishStatus.pending]);

      expect(response.counts[KitchenFilter.all], 12);
      expect(response.counts[KitchenFilter.accepted], 2);
      expect(response.counts[KitchenFilter.cooking], 6);
      expect(response.counts[KitchenFilter.ready], 3);
      expect(response.counts[KitchenFilter.canceled], 1);
      expect(response.total, 12);
    });

    test('garbage body parses to the empty response', () {
      expect(KitchenOrdersResponse.fromJson('<html>').orders, isEmpty);
      expect(KitchenOrdersResponse.fromJson(null).total, 0);
    });
  });

  group('dish preview data', () {
    test('dishStatuses reflects every line', () {
      const order = KitchenOrderData(
        dishes: [
          KitchenDishData(id: 'a', prepStatus: DishStatus.done),
          KitchenDishData(id: 'b'),
        ],
      );
      expect(order.dishStatuses, [DishStatus.done, DishStatus.pending]);
    });
  });
}
