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

// The driver home sheet's LAYOUT CONTRACT, pinned after the guided tour
// died on it.
//
// `BottomSheetScreen` returns an `AnimatedPositioned`, so the widget is
// only ever legal as a direct child of the home page's `Stack`, and the
// Stack gives a child positioned on ONE axis no horizontal bound at all.
// While the sheet was a single self-sizing `Container` that was
// survivable; the moment the weather banner turned it into a
// `Column(crossAxisAlignment: stretch)` the column started handing its
// children `w=Infinity` and the driver home stopped laying out at all:
//
//   BoxConstraints forces an infinite width.
//     BoxConstraints(w=Infinity, 0.0<=h<=Infinity)
//   The relevant error-causing widget was: Column
//     .../lib/presentation/pages/home/bottom_sheet_screen.dart
//
// So the sheet must pin BOTH horizontal edges. These tests pump the real
// template in the frame it actually renders in — a Stack under a
// Scaffold body — and fail on any exception, which is precisely what the
// tour reported. Deleting `left: 0, right: 0`, or reintroducing a
// stretching column that is not width-bounded, turns them red.
//
// The template is imported by relative path because `templates/` is what
// the composer installs into the host's generated `lib/`; this particular
// file carries no composer placeholders, so it is the same source the
// host compiles.
//
// The second group pins the sheet's CARD GATES, which are two INDEPENDENT
// conditions over one Column — `cashOrderCount > 0` for chip 932 and
// `hasOpenLoad` for the van-sales tile. Nesting one inside the other, or
// letting either borrow the other's predicate, would hide the load from a
// driver who was just handed one and has sold nothing yet: the exact
// moment the tile matters most.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/handlers/handlers.dart';

import 'package:delivery_sdk/src/driver/application/home/driver_home_notifier.dart';
import 'package:delivery_sdk/src/driver/application/home/driver_home_provider.dart';
import 'package:delivery_sdk/src/driver/application/load/load_notifier.dart';
import 'package:delivery_sdk/src/driver/application/load/load_provider.dart';
import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_day_report.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/load_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/orders_repository.dart';

import 'support/demo_fixtures_harness.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';
import 'package:delivery_sdk/src/driver/presentation/home/cash_on_hand_card.dart';

import '../templates/pages/driver/home/bottom_sheet_screen.dart';

const Size _phone = Size(390, 900);

/// Pump the sheet exactly where `home_page.dart` puts it: a direct child
/// of a `Stack` that also carries the (non-positioned) map, inside a
/// Scaffold body.
Future<void> _pumpSheet(WidgetTester tester, {bool isScrolling = false}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: _phone,
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Stands in for `_map(context, ref)` — the non-positioned
                // child the real Stack sizes itself from.
                const SizedBox.expand(),
                BottomSheetScreen(isScrolling: isScrolling),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A day report the test dictates, so the cash card's gate is set by the
/// test rather than by whatever the demo fixtures happen to hold.
class _ReportingOrders extends CourierOrdersRepository {
  _ReportingOrders(this.report);

  final DriverDayReport report;

  @override
  Future<ApiResult<DriverDayReport>> getDayReport({
    required DateTime from,
    required DateTime to,
  }) async =>
      ApiResult.success(data: report);
}

/// A load repository that serves exactly the loads the test names.
class _StaticLoads implements DriverLoadRepositoryFacade {
  _StaticLoads(this.loads);

  final List<DriverLoad> loads;

  @override
  Future<ApiResult<List<DriverLoad>>> getMyLoad() async =>
      ApiResult.success(data: loads);

  @override
  Future<ApiResult<DriverLoadSale>> createLoadSale({
    required String loadOrder,
    required List<DriverLoadMovement> items,
    String? customer,
    String? note,
    String? poi,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<DriverLoad>> returnLoad({
    required String loadOrder,
    required List<DriverLoadMovement> items,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<DriverLoad>> closeLoad({required String loadOrder}) =>
      throw UnimplementedError();
}

DriverLoad _openLoad() => DriverLoad.fromJson(const {
      'id': 'LOAD-4',
      'shop': {'id': 'SHOP-1', 'title': 'Depot North'},
      'load_status': 'Open',
      'lines': [
        {
          'stock_id': 'STK-1',
          'unit_price': 45,
          'issued_qty': 10,
          'sold_qty': 0,
          'returned_qty': 0,
          'remaining_qty': 10,
          'product': {
            'translation': {'title': 'Still water 5L'},
          },
        },
      ],
    });

/// The sheet with both gates driven from the test: a day report, and a
/// load list.
Future<void> _pumpGated(
  WidgetTester tester, {
  required DriverDayReport report,
  required List<DriverLoad> loads,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final loadNotifier = DriverLoadNotifier(
    _StaticLoads(loads),
    // Never reach the connectivity plugin from a widget test.
    isOnline: () async => true,
  );
  await loadNotifier.load();
  final homeNotifier = DriverHomeNotifier(_ReportingOrders(report));
  await homeNotifier.refresh();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        driverLoadProvider.overrideWith((ref) => loadNotifier),
        driverHomeProvider.overrideWith((ref) => homeNotifier),
      ],
      child: ScreenUtilInit(
        designSize: _phone,
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const SizedBox.expand(),
                const BottomSheetScreen(isScrolling: false),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() async {
    // The real repositories in a demo session, answered from the demo
    // fixtures by base_sdk's DemoGatewayInterceptor.
    await startDemoFixtures();
    final GetIt getIt = GetIt.instance;
    if (!getIt.isRegistered<CourierOrdersRepositoryFacade>()) {
      getIt.registerSingleton<CourierOrdersRepositoryFacade>(
        CourierOrdersRepository(),
      );
    }
    // The sheet reads the driver's consignment load for its "My load"
    // tile; the demo fixture serves no load, so the tile is absent and
    // this file keeps testing the layout it was written for.
    if (!getIt.isRegistered<DriverLoadRepositoryFacade>()) {
      getIt.registerSingleton<DriverLoadRepositoryFacade>(
        DriverLoadRepository(),
      );
    }
  });

  tearDown(() async {
    await stopDemoFixtures();
    await GetIt.instance.reset();
  });

  group('the driver home sheet lays out inside the home Stack', () {
    testWidgets('off duty - no infinite-width assert', (tester) async {
      await _pumpSheet(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on duty - no infinite-width assert', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'keyOnline': true,
      });
      await CourierStorage.init();
      await _pumpSheet(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tucked away while the map scrolls - still lays out', (
      tester,
    ) async {
      await _pumpSheet(tester, isScrolling: true);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the sheet spans the full width of the stack', (tester) async {
      await _pumpSheet(tester);
      expect(tester.takeException(), isNull);
      final Finder column = find
          .descendant(
            of: find.byType(BottomSheetScreen),
            matching: find.byType(Column),
          )
          .first;
      // Both horizontal edges pinned: the column is as wide as the phone,
      // never unbounded and never intrinsically sized.
      expect(tester.getSize(column).width, _phone.width);
    });
  });

  group('the sheet card gates are independent', () {
    testWidgets('an open load with no cash orders still shows My load', (
      tester,
    ) async {
      // The moment the tile matters most: the shop has just handed him a
      // load and he has sold nothing, so there is no cash on hand at all.
      await _pumpGated(
        tester,
        report: const DriverDayReport(cashOnHand: 0, cashOrderCount: 0),
        loads: [_openLoad()],
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('driverHomeMyLoadCard')), findsOneWidget);
      expect(find.byType(CashOnHandCard), findsNothing);
    });

    testWidgets('cash orders with no load show only the cash card', (
      tester,
    ) async {
      await _pumpGated(
        tester,
        report: const DriverDayReport(cashOnHand: 470, cashOrderCount: 1),
        loads: const [],
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CashOnHandCard), findsOneWidget);
      expect(find.byKey(const Key('driverHomeMyLoadCard')), findsNothing);
    });

    testWidgets('carrying both, both cards are drawn', (tester) async {
      await _pumpGated(
        tester,
        report: const DriverDayReport(cashOnHand: 470, cashOrderCount: 1),
        loads: [_openLoad()],
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CashOnHandCard), findsOneWidget);
      expect(find.byKey(const Key('driverHomeMyLoadCard')), findsOneWidget);
    });

    testWidgets('a closed load is not an open one, so no tile', (
      tester,
    ) async {
      final closed = DriverLoad.fromJson(const {
        'id': 'LOAD-4',
        'load_status': 'Closed',
        'lines': [
          {'stock_id': 'STK-1', 'unit_price': 45, 'remaining_qty': 10},
        ],
      });
      await _pumpGated(
        tester,
        report: const DriverDayReport(cashOnHand: 0, cashOrderCount: 0),
        loads: [closed],
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('driverHomeMyLoadCard')), findsNothing);
    });
  });
}
