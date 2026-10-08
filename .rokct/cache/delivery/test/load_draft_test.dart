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

// THE CEILING AND THE TOTAL — the part that can be wrong with money.
//
// The server refuses a quantity above `remaining`. If the stepper let a
// driver dial past that, the only thing he would learn is that the app
// lied to him, at the door, in front of a customer. So the cap is enforced
// where it can be tested, not inside a widget.

import 'package:delivery_sdk/src/driver/application/load/load_draft.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:flutter_test/flutter_test.dart';

DriverLoad _load() => DriverLoad.fromJson({
      'id': 'LOAD-4',
      'lines': [
        {
          'stock_id': 'STK-1',
          'unit_price': 45,
          'issued_qty': 10,
          'sold_qty': 3,
          'returned_qty': 1,
          'remaining_qty': 6,
          'product': {'translation': {'title': 'Still water 5L'}},
        },
        {
          'stock_id': 'STK-2',
          'unit_price': 20,
          'issued_qty': 4,
          'sold_qty': 0,
          'returned_qty': 0,
          'remaining_qty': 2,
          'product': {'translation': {'title': 'Ice 2kg'}},
        },
      ],
    });

LoadDraft _pick(DriverLoad load, Map<int, int> picks) {
  var draft = const LoadDraft();
  picks.forEach((index, quantity) {
    draft = draft.setQuantity(load.lines[index], quantity);
  });
  return draft;
}

void main() {
  group('the cap', () {
    test('is the server remaining figure', () {
      final load = _load();
      expect(LoadDraft.capFor(load.lines[0]), 6);
      expect(LoadDraft.capFor(load.lines[1]), 2);
    });

    test('increment stops AT the cap instead of going past it', () {
      final load = _load();
      var draft = const LoadDraft();
      for (var i = 0; i < 10; i++) {
        draft = draft.increment(load.lines[1]);
      }
      expect(draft.quantityFor(load.lines[1]), 2);
      expect(draft.isAtCap(load.lines[1]), isTrue);
    });

    test('an explicit quantity above remaining is clamped, never refused',
        () {
      final load = _load();
      final draft = const LoadDraft().setQuantity(load.lines[0], 99);
      expect(draft.quantityFor(load.lines[0]), 6);
    });

    test('decrement never goes below zero and drops the line', () {
      final load = _load();
      var draft = const LoadDraft().increment(load.lines[0]);
      draft = draft.decrement(load.lines[0]).decrement(load.lines[0]);
      expect(draft.quantityFor(load.lines[0]), 0);
      expect(draft.isEmpty, isTrue);
      expect(draft.quantities, isEmpty);
    });

    test('a line with no remaining cannot be picked at all', () {
      final load = DriverLoad.fromJson({
        'id': 'L',
        'lines': [
          {'stock_id': 'STK-9', 'unit_price': 10, 'remaining_qty': 0},
        ],
      });
      final draft = const LoadDraft().increment(load.lines.single);
      expect(draft.quantityFor(load.lines.single), 0);
      expect(LoadDraft.capFor(load.lines.single), 0);
    });

    test('a line with no stock row cannot be picked at all', () {
      final load = DriverLoad.fromJson({
        'id': 'L',
        'lines': [
          {'unit_price': 10, 'remaining_qty': 5},
        ],
      });
      expect(LoadDraft.capFor(load.lines.single), 0);
      expect(
        const LoadDraft().increment(load.lines.single).isEmpty,
        isTrue,
      );
    });

    test('a fractional remainder caps at the whole units available', () {
      final load = DriverLoad.fromJson({
        'id': 'L',
        'lines': [
          {'stock_id': 'STK-7', 'unit_price': 8, 'remaining_qty': 2.5},
        ],
      });
      expect(LoadDraft.capFor(load.lines.single), 2);
    });
  });

  group('the total', () {
    test('is struck at each line own unit price', () {
      final load = _load();
      // 3 x 45 + 2 x 20.
      final draft = _pick(load, {0: 3, 1: 2});
      expect(draft.totalFor(load), 175);
      expect(draft.totalUnitsFor(load), 5);
    });

    test('an untouched draft is zero and inert', () {
      final load = _load();
      const draft = LoadDraft();
      expect(draft.totalFor(load), 0);
      expect(draft.totalUnitsFor(load), 0);
      expect(draft.isEmpty, isTrue);
      expect(draft.isNotEmpty, isFalse);
      expect(draft.movementsFor(load), isEmpty);
    });

    test('a clamped pick is charged at the clamped quantity', () {
      final load = _load();
      // Asked for 99 of a line with 6 left: 6 x 45, not 99 x 45.
      final draft = _pick(load, {0: 99});
      expect(draft.totalFor(load), 270);
    });
  });

  group('the wire lines', () {
    test('carry stock and quantity in the load own order', () {
      final load = _load();
      final movements = _pick(load, {1: 2, 0: 3}).movementsFor(load);
      expect(movements.map((m) => m.stockId), ['STK-1', 'STK-2']);
      expect(movements.map((m) => m.quantity), [3, 2]);
      expect(movements.first.toJson(), {'stock': 'STK-1', 'quantity': 3});
    });

    test('skip the lines the driver never touched', () {
      final load = _load();
      expect(_pick(load, {1: 1}).movementsFor(load), hasLength(1));
    });
  });

  group('rebasing after a write', () {
    test('re-clamps against the load as the server now reports it', () {
      final before = _load();
      final draft = _pick(before, {0: 5, 1: 2});

      // The sale went through: 4 of the first line are gone.
      final after = DriverLoad.fromJson({
        'id': 'LOAD-4',
        'lines': [
          {'stock_id': 'STK-1', 'unit_price': 45, 'remaining_qty': 2},
          {'stock_id': 'STK-2', 'unit_price': 20, 'remaining_qty': 2},
        ],
      });
      final rebased = draft.rebasedOn(after);

      expect(rebased.quantityFor(after.lines[0]), 2);
      expect(rebased.quantityFor(after.lines[1]), 2);
      expect(rebased.totalFor(after), 130);
    });

    test('drops a line the server no longer has anything left on', () {
      final before = _load();
      final draft = _pick(before, {0: 3});
      final after = DriverLoad.fromJson({
        'id': 'LOAD-4',
        'lines': [
          {'stock_id': 'STK-1', 'unit_price': 45, 'remaining_qty': 0},
        ],
      });
      expect(draft.rebasedOn(after).isEmpty, isTrue);
    });
  });
}
