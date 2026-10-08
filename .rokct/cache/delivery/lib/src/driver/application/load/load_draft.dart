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

/// THE CEILING AND THE TOTAL, out of the widgets.
///
/// Both write screens are the same arithmetic: a quantity per line, capped
/// at what the server says is remaining, and a running total struck at the
/// load's own unit price. It lives here, in a plain immutable value, for
/// one reason: it is the part that can be WRONG WITH MONEY, so it has to
/// be testable without pumping a widget.
///
/// The cap is not a validation message. The server refuses a quantity above
/// remaining, and a driver who can dial past the limit only to be refused
/// has been lied to by the stepper. So [increment] simply stops, and
/// [isAtCap] is what greys the plus.
///
/// Quantities move in whole units. A load line may carry a fractional
/// remainder (Frappe quantity fields are floats), so the cap is the whole
/// units available — [capFor] floors it — and a fractional tail is returned
/// or closed out rather than sold by stepper.
library;

import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';

class LoadDraft {
  const LoadDraft({this.quantities = const {}});

  /// stock id -> whole units picked. A line the driver has not touched is
  /// absent rather than zero, so an untouched draft is `isEmpty`.
  final Map<String, int> quantities;

  /// Nothing picked yet — what keeps the commit inert.
  bool get isEmpty => quantities.values.every((qty) => qty <= 0);

  bool get isNotEmpty => !isEmpty;

  /// Whole units available on [line]: the server's remaining, floored.
  /// A line with no stock row cannot be moved at all.
  static int capFor(DriverLoadLine line) {
    if (line.stockId == null) return 0;
    final remaining = line.remainingQty;
    if (remaining <= 0) return 0;
    return remaining.floor();
  }

  int quantityFor(DriverLoadLine line) {
    final stockId = line.stockId;
    if (stockId == null) return 0;
    return quantities[stockId] ?? 0;
  }

  bool isAtCap(DriverLoadLine line) => quantityFor(line) >= capFor(line);

  /// One more unit of [line], or this draft unchanged when the line is
  /// already at the server's ceiling.
  LoadDraft increment(DriverLoadLine line) =>
      _set(line, quantityFor(line) + 1);

  /// One fewer, never below zero.
  LoadDraft decrement(DriverLoadLine line) =>
      _set(line, quantityFor(line) - 1);

  /// An explicit figure, clamped into `0..cap`.
  LoadDraft setQuantity(DriverLoadLine line, int quantity) =>
      _set(line, quantity);

  LoadDraft _set(DriverLoadLine line, int quantity) {
    final stockId = line.stockId;
    if (stockId == null) return this;
    final cap = capFor(line);
    final clamped = quantity < 0 ? 0 : (quantity > cap ? cap : quantity);
    if (clamped == quantityFor(line)) return this;
    final next = Map<String, int>.from(quantities);
    if (clamped == 0) {
      next.remove(stockId);
    } else {
      next[stockId] = clamped;
    }
    return LoadDraft(quantities: next);
  }

  /// Re-clamps every picked quantity against [load] as it now stands. Run
  /// after a write lands: a sale that went through lowers remaining, and a
  /// draft still holding the old figure would offer what is no longer
  /// there.
  LoadDraft rebasedOn(DriverLoad load) {
    var next = const LoadDraft();
    for (final line in load.lines) {
      final picked = quantityFor(line);
      if (picked > 0) next = next.setQuantity(line, picked);
    }
    return next;
  }

  /// The cash figure, struck at each line's own `unit_price`. This is both
  /// what the sell screen shows live and what the success sheet names as
  /// the amount to collect.
  num totalFor(DriverLoad load) {
    num total = 0;
    for (final line in load.lines) {
      total += quantityFor(line) * line.unitPrice;
    }
    return total;
  }

  int totalUnitsFor(DriverLoad load) {
    var units = 0;
    for (final line in load.lines) {
      units += quantityFor(line);
    }
    return units;
  }

  /// The wire lines, in the load's own order, skipping untouched rows.
  List<DriverLoadMovement> movementsFor(DriverLoad load) {
    final movements = <DriverLoadMovement>[];
    for (final line in load.lines) {
      final stockId = line.stockId;
      final quantity = quantityFor(line);
      if (stockId == null || quantity <= 0) continue;
      movements.add(
        DriverLoadMovement(stockId: stockId, quantity: quantity),
      );
    }
    return movements;
  }
}
