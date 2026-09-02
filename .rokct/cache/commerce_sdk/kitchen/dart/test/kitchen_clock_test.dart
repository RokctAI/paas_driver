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
// The kitchen flip clock: threshold colours (white / amber at 30 / red
// "Delayed" at 60 — POS orders_info.dart), and the FREEZE-AT-READY rule
// with the approved dim treatment.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_clock.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/services/local_storage.dart';

Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(1280, 800),
  builder: (_, __) => MaterialApp(home: Scaffold(body: Center(child: child))),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  group('KitchenClock.mode — the POS thresholds', () {
    test('accepted shows no clock (the Just-in ping instead)', () {
      expect(
        KitchenClock.mode(
          status: KitchenStatus.accepted,
          elapsed: const Duration(minutes: 5),
        ),
        KitchenClockMode.none,
      );
    });

    test('cooking: white under 30, amber at 30, red Delayed at 60', () {
      expect(
        KitchenClock.mode(
          status: KitchenStatus.cooking,
          elapsed: const Duration(minutes: 29, seconds: 59),
        ),
        KitchenClockMode.normal,
      );
      expect(
        KitchenClock.mode(
          status: KitchenStatus.cooking,
          elapsed: const Duration(minutes: 30),
        ),
        KitchenClockMode.warn,
      );
      expect(
        KitchenClock.mode(
          status: KitchenStatus.cooking,
          elapsed: const Duration(minutes: 74),
        ),
        KitchenClockMode.delayed,
      );
    });

    test('ready and cancelled freeze', () {
      for (final status in [KitchenStatus.ready, KitchenStatus.canceled]) {
        expect(
          KitchenClock.mode(status: status, elapsed: const Duration(minutes: 5)),
          KitchenClockMode.frozen,
        );
      }
    });
  });

  group('KitchenClock.frozenEnd — the freeze rule', () {
    final updated = DateTime(2026, 8, 29, 12, 3);

    test('READY freezes the clock at updatedAt', () {
      expect(
        KitchenClock.frozenEnd(status: KitchenStatus.ready, updatedAt: updated),
        updated,
      );
      expect(
        KitchenClock.frozenEnd(
          status: KitchenStatus.canceled,
          updatedAt: updated,
        ),
        updated,
      );
    });

    test('live statuses keep ticking (null)', () {
      expect(
        KitchenClock.frozenEnd(
          status: KitchenStatus.cooking,
          updatedAt: updated,
        ),
        isNull,
      );
      expect(
        KitchenClock.frozenEnd(
          status: KitchenStatus.accepted,
          updatedAt: updated,
        ),
        isNull,
      );
    });
  });

  group('KitchenClock.faces', () {
    test('hours tile only when > 0 (POS orders_info.dart:239-256)', () {
      final short = KitchenClock.faces(
        const Duration(minutes: 36, seconds: 5),
      );
      expect(short.hh, '');
      expect(short.mm, '36');
      expect(short.ss, '05');

      final long = KitchenClock.faces(
        const Duration(hours: 1, minutes: 14, seconds: 48),
      );
      expect(long.hh, '01');
      expect(long.mm, '14');
      expect(long.ss, '48');
    });

    test('negative clamps to zero', () {
      final faces = KitchenClock.faces(const Duration(seconds: -5));
      expect(faces.mm, '00');
      expect(faces.ss, '00');
    });
  });

  group('KitchenFlipClock widget', () {
    testWidgets('a READY order renders the frozen span, dimmed, no timer',
        (tester) async {
      final created = DateTime(2026, 8, 29, 11, 44);
      final updated = created.add(const Duration(minutes: 22, seconds: 40));
      await tester.pumpWidget(
        _host(
          KitchenFlipClock(
            status: KitchenStatus.ready,
            createdAt: created,
            updatedAt: updated,
            // "now" far later — a frozen clock must ignore it.
            clock: () => created.add(const Duration(hours: 9)),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('22'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      // The approved dim treatment (POS: 50%; frames: 45%).
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('22'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, closeTo(0.45, 0.001));
      // Frozen: no ticking timer keeps the tree dirty.
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a cooking order past the hour shows the red Delayed tag',
        (tester) async {
      final created = DateTime(2026, 8, 29, 11, 19);
      await tester.pumpWidget(
        _host(
          KitchenFlipClock(
            status: KitchenStatus.cooking,
            createdAt: created,
            updatedAt: created,
            clock: () => created.add(
              const Duration(hours: 1, minutes: 14, seconds: 48),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('01'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      // The tag key humanizes to 'Delayed' with no store seeded.
      expect(find.textContaining('Delayed'), findsOneWidget);
      // A live cooking clock ticks — kill the timer before the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an accepted order renders nothing (Just-in ping territory)',
        (tester) async {
      await tester.pumpWidget(
        _host(
          KitchenFlipClock(
            status: KitchenStatus.accepted,
            createdAt: DateTime(2026, 8, 29, 12, 31),
            updatedAt: null,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.textContaining(':'), findsNothing);
    });
  });
}
