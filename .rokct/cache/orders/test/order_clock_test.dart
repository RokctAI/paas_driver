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
// The per-card clock of the approved board: elapsed formatting and the
// FREEZE-AT-READY rule (POS drag_item.dart OrderTimerNotifier), plus the
// ticking widget itself.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:orders_sdk/src/manager/presentation/board/order_clock.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(1280, 800),
  builder: (_, __) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('OrderClock.elapsed (POS _calculateTimeDifference)', () {
    test('minutes, hours, days', () {
      expect(OrderClock.elapsed(const Duration(seconds: 40)), '0m');
      expect(OrderClock.elapsed(const Duration(minutes: 4)), '4m');
      expect(OrderClock.elapsed(const Duration(minutes: 75)), '1h');
      expect(OrderClock.elapsed(const Duration(hours: 26)), '1d');
    });
  });

  group('OrderClock.frozenEnd — the freeze rule', () {
    final updated = DateTime(2026, 8, 29, 12, 3);

    test('READY freezes the clock at updatedAt', () {
      expect(
        OrderClock.frozenEnd(status: BoardStatus.ready, updatedAt: updated),
        updated,
      );
    });

    test('history statuses freeze too (a delivered order has a lifetime)', () {
      expect(
        OrderClock.frozenEnd(status: BoardStatus.delivered, updatedAt: updated),
        updated,
      );
      expect(
        OrderClock.frozenEnd(status: BoardStatus.canceled, updatedAt: updated),
        updated,
      );
    });

    test('live statuses keep ticking (no frozen end)', () {
      for (final status in [
        BoardStatus.newOrder,
        BoardStatus.accepted,
        BoardStatus.cooking,
        BoardStatus.onWay,
      ]) {
        expect(
          OrderClock.frozenEnd(status: status, updatedAt: updated),
          isNull,
        );
      }
    });
  });

  group('OrderClockRow widget', () {
    testWidgets('ticks every second while the order is live', (tester) async {
      final start = DateTime(2026, 8, 29, 12, 0);
      // Injectable clock: the widget test's fake async advances timers,
      // not the wall clock, so the tick reads "now" from here.
      DateTime now = start.add(const Duration(minutes: 4));
      await tester.pumpWidget(
        _host(
          OrderClockRow(
            createdAt: start,
            updatedAt: null,
            status: BoardStatus.newOrder,
            clock: () => now,
          ),
        ),
      );
      expect(find.text('4m'), findsOneWidget);

      // Cross the next minute boundary: the 1s timer must repaint it.
      now = start.add(const Duration(minutes: 5, seconds: 1));
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('5m'), findsOneWidget);

      // Live widget holds a periodic timer — dispose it cleanly.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('frozen at READY: no timer runs and the range is fixed', (
      tester,
    ) async {
      final start = DateTime(2026, 8, 29, 11, 57);
      final readyAt = DateTime(2026, 8, 29, 12, 3);
      await tester.pumpWidget(
        _host(
          OrderClockRow(
            createdAt: start,
            updatedAt: readyAt,
            status: BoardStatus.ready,
          ),
        ),
      );
      expect(find.text('6m'), findsOneWidget);
      expect(find.text(OrderClock.range(start, readyAt)), findsOneWidget);

      // No pending periodic timer: pumping far ahead changes nothing —
      // and the test framework would fail on a leaked timer otherwise.
      await tester.pump(const Duration(minutes: 10));
      expect(find.text('6m'), findsOneWidget);
      expect(find.text(OrderClock.range(start, readyAt)), findsOneWidget);
    });
  });
}
