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
// Window math behind the period chips (654/655) and the delta pills (657).

import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/manager/application/profit/revenue_period.dart';

void main() {
  // The approved frame's week: 24–30 Aug 2026 (Mon–Sun); "now" mid-week.
  final now = DateTime(2026, 8, 27, 14, 30);

  test('today: single day, previous = yesterday (backend goes hourly)', () {
    final window = RevenueWindow.of(RevenuePeriod.today, now);
    expect(window.from, DateTime(2026, 8, 27));
    expect(window.to, DateTime(2026, 8, 27));
    expect(window.previousFrom, DateTime(2026, 8, 26));
    expect(window.previousTo, DateTime(2026, 8, 26));
  });

  test('week: Monday..Sunday of the current week — the 24–30 Aug frame', () {
    final window = RevenueWindow.of(RevenuePeriod.week, now);
    expect(window.from, DateTime(2026, 8, 24));
    expect(window.to, DateTime(2026, 8, 30));
    expect(window.previousFrom, DateTime(2026, 8, 17));
    expect(window.previousTo, DateTime(2026, 8, 23));
  });

  test('month: the calendar month, previous = last month', () {
    final window = RevenueWindow.of(RevenuePeriod.month, now);
    expect(window.from, DateTime(2026, 8, 1));
    expect(window.to, DateTime(2026, 8, 31));
    expect(window.previousFrom, DateTime(2026, 7, 1));
    expect(window.previousTo, DateTime(2026, 7, 31));
  });

  test('custom: inclusive picked range, previous shifts by the same span',
      () {
    final window = RevenueWindow.of(
      RevenuePeriod.custom,
      now,
      customFrom: DateTime(2026, 8, 10),
      customTo: DateTime(2026, 8, 13),
    );
    expect(window.from, DateTime(2026, 8, 10));
    expect(window.to, DateTime(2026, 8, 13));
    expect(window.previousFrom, DateTime(2026, 8, 6));
    expect(window.previousTo, DateTime(2026, 8, 9));
  });

  test('delta pills: percent vs previous, HONESTLY null when incomputable',
      () {
    expect(percentDelta(108.2, 100), closeTo(8.2, 1e-9));
    expect(percentDelta(90, 100), closeTo(-10, 1e-9));
    // No previous period data -> no pill, never a fake +100%.
    expect(percentDelta(50, 0), isNull);
  });

  test('margin deltas move in points', () {
    expect(pointDelta(41.4, 40.3, hasBoth: true), closeTo(1.1, 1e-9));
    expect(pointDelta(41.4, 40.3, hasBoth: false), isNull);
  });
}
