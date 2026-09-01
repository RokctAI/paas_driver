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
// The approved board's rule layer (frames 33a/33b + the drag-skip frame):
// the seven-status axis, the SMART SKIP mapping (POS board_view.dart
// lines 266-273), the waiter column rule, and the forward-only drag rule.

import 'package:base_sdk/src/services/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_sound.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';

void main() {
  group('BoardStatus axis', () {
    test('wire strings are the POS legacy ones', () {
      expect(BoardStatus.newOrder.wire, 'new');
      expect(BoardStatus.accepted.wire, 'accepted');
      expect(BoardStatus.cooking.wire, 'cooking');
      expect(BoardStatus.ready.wire, 'ready');
      expect(BoardStatus.onWay.wire, 'on_a_way');
      expect(BoardStatus.delivered.wire, 'delivered');
      expect(BoardStatus.canceled.wire, 'canceled');
    });

    test('maps onto base OrderStatus everywhere except cooking', () {
      expect(BoardStatus.newOrder.orderStatus, OrderStatus.open);
      expect(BoardStatus.accepted.orderStatus, OrderStatus.accepted);
      expect(BoardStatus.cooking.orderStatus, isNull);
      expect(BoardStatus.ready.orderStatus, OrderStatus.ready);
      expect(BoardStatus.onWay.orderStatus, OrderStatus.onWay);
      expect(BoardStatus.delivered.orderStatus, OrderStatus.delivered);
      expect(BoardStatus.canceled.orderStatus, OrderStatus.canceled);
    });

    test('progress runs 0/20/40/60/80/100 (POS getProgressPercentage)', () {
      expect(BoardStatus.newOrder.progress, 0.0);
      expect(BoardStatus.accepted.progress, 0.2);
      expect(BoardStatus.cooking.progress, 0.4);
      expect(BoardStatus.ready.progress, 0.6);
      expect(BoardStatus.onWay.progress, 0.8);
      expect(BoardStatus.delivered.progress, 1.0);
      expect(BoardStatus.canceled.progress, 1.0);
    });

    test('fromWire round-trips and defaults unknowns to new', () {
      for (final status in BoardStatus.values) {
        expect(BoardStatus.fromWire(status.wire), status);
      }
      expect(BoardStatus.fromWire('nonsense'), BoardStatus.newOrder);
      expect(BoardStatus.fromWire(null), BoardStatus.newOrder);
    });
  });

  group('smart skip (POS board_view.dart:266-273)', () {
    test('a PICKUP dropped on On the way lands in Delivered', () {
      expect(
        BoardRules.resolveDrop(
          target: BoardStatus.onWay,
          deliveryType: 'pickup',
        ),
        BoardStatus.delivered,
      );
      // The POS predicate is "neither dine nor delivery": a null/unknown
      // type never travels with a driver either.
      expect(
        BoardRules.resolveDrop(target: BoardStatus.onWay, deliveryType: null),
        BoardStatus.delivered,
      );
    });

    test('delivery and dine-in orders keep the On-the-way target', () {
      expect(
        BoardRules.resolveDrop(
          target: BoardStatus.onWay,
          deliveryType: 'delivery',
        ),
        BoardStatus.onWay,
      );
      expect(
        BoardRules.resolveDrop(
          target: BoardStatus.onWay,
          deliveryType: 'dine_in',
        ),
        BoardStatus.onWay,
      );
    });

    test('every other target is untouched, pickup or not', () {
      for (final target in BoardStatus.values) {
        if (target == BoardStatus.onWay) continue;
        expect(
          BoardRules.resolveDrop(target: target, deliveryType: 'pickup'),
          target,
        );
      }
    });
  });

  group('waiter rule', () {
    test('a waiter login loses the On-the-way column', () {
      final columns = BoardRules.columnsFor(role: BoardRules.waiterRole);
      expect(columns, isNot(contains(BoardStatus.onWay)));
      expect(columns, hasLength(6));
    });

    test('every other role sees all seven, in flow order', () {
      for (final role in [null, 'seller', 'manager']) {
        expect(BoardRules.columnsFor(role: role), BoardStatus.values);
      }
    });
  });

  group('forward-only drag rule', () {
    test('drops are legal only from an earlier column to a later one', () {
      expect(
        BoardRules.canMove(
          from: BoardStatus.newOrder,
          to: BoardStatus.accepted,
        ),
        isTrue,
      );
      expect(
        BoardRules.canMove(
          from: BoardStatus.accepted,
          to: BoardStatus.newOrder,
        ),
        isFalse,
      );
      expect(
        BoardRules.canMove(from: BoardStatus.ready, to: BoardStatus.ready),
        isFalse,
      );
      // Cancelling from any active column is a forward move.
      expect(
        BoardRules.canMove(from: BoardStatus.cooking, to: BoardStatus.canceled),
        isTrue,
      );
    });
  });

  group('new-order chime (POS _checkAndPlaySound)', () {
    test('baselines silently, rings on growth, re-baselines after', () {
      final chime = NewOrderChime();
      // First observation only baselines — no chime on initial load.
      expect(chime.register(newCount: 3, acceptedCount: 1), isFalse);
      // No growth, no chime.
      expect(chime.register(newCount: 3, acceptedCount: 1), isFalse);
      // A new order landed.
      expect(chime.register(newCount: 4, acceptedCount: 1), isTrue);
      // An accepted order landed.
      expect(chime.register(newCount: 4, acceptedCount: 2), isTrue);
      // Shrinking (order moved on) stays silent.
      expect(chime.register(newCount: 2, acceptedCount: 1), isFalse);
    });
  });
}
