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

// Van sales as the driver sees it.
//
// The route SHELLS live in `templates/` and only compile inside a composed
// host, so what is pumped here is what those shells render: the SDK's own
// `DriverLoadPlane`, `LoadSalePlane`, `LoadReturnPlane` and the close
// dialog. Every screen on the seam except the three one-line @RoutePage
// wrappers is therefore under test.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * "no load" NEVER shows before the first answer — a driver whose read
//     is still in flight must not be told his van is empty;
//   * the empty state stays ONE sentence with no call to action: he cannot
//     issue himself a load;
//   * the steppers stop at the server's remaining figure, and the total is
//     struck at the load's own unit prices;
//   * the close confirm STATES the wallet charge before the button that
//     causes it.

import 'dart:async';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:delivery_sdk/src/driver/application/load/load_notifier.dart';
import 'package:delivery_sdk/src/driver/application/load/load_provider.dart';
import 'package:delivery_sdk/src/driver/application/poi/poi_notifier.dart';
import 'package:delivery_sdk/src/driver/application/poi/poi_provider.dart';
import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/domain/interface/poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_fix.dart';
import 'package:delivery_sdk/src/driver/presentation/home/my_load_card.dart';
import 'package:delivery_sdk/src/driver/presentation/load/driver_load_plane.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_close_flow.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_return_plane.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_sale_plane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadJson({String id = 'LOAD-4'}) => {
      'id': id,
      'shop': {'id': 'SHOP-1', 'title': 'Depot North'},
      'load_status': 'Open',
      'lines': [
        {
          'item_id': 'LI-1',
          'stock_id': 'STK-1',
          'unit_price': 45,
          'issued_qty': 10,
          'sold_qty': 3,
          'returned_qty': 1,
          'remaining_qty': 6,
          'product': {
            'uuid': 'PRD-WATER-5L',
            'translation': {'title': 'Still water 5L'},
            'unit': {'translation': {'title': 'bottle'}},
          },
        },
        {
          'stock_id': 'STK-2',
          'unit_price': 20,
          'issued_qty': 4,
          'sold_qty': 2,
          'returned_qty': 0,
          'remaining_qty': 2,
          'product': {
            'translation': {'title': 'Ice 2kg'},
            'unit': {'translation': {'title': 'bag'}},
          },
        },
      ],
    };

/// A repository that answers from memory, so the whole flow runs without a
/// server or a platform channel.
class _FakeLoadRepository implements DriverLoadRepositoryFacade {
  _FakeLoadRepository({this.loads = const []});

  List<DriverLoad> loads;

  /// When set, `getMyLoad` never answers — the state a driver is in for
  /// the first second of every entry, and the one the empty sentence must
  /// not appear in.
  Completer<void>? gate;
  /// (load order, lines, customer, note, point of interest).
  final List<(String, List<DriverLoadMovement>, String?, String?, String?)>
      sales = [];
  final List<(String, List<DriverLoadMovement>)> returns = [];
  final List<String> closes = [];

  DriverLoad? saleAnswer;
  DriverLoad? returnAnswer;
  DriverLoad? closeAnswer;
  String saleOrderId = 'ORD-77';

  @override
  Future<ApiResult<List<DriverLoad>>> getMyLoad() async {
    final held = gate;
    if (held != null) await held.future;
    return ApiResult.success(data: loads);
  }

  @override
  Future<ApiResult<DriverLoadSale>> createLoadSale({
    required String loadOrder,
    required List<DriverLoadMovement> items,
    String? customer,
    String? note,
    String? poi,
  }) async {
    sales.add((loadOrder, items, customer, note, poi));
    return ApiResult.success(
      data: DriverLoadSale(orderId: saleOrderId, load: saleAnswer),
    );
  }

  @override
  Future<ApiResult<DriverLoad>> returnLoad({
    required String loadOrder,
    required List<DriverLoadMovement> items,
  }) async {
    returns.add((loadOrder, items));
    return ApiResult.success(
      data: returnAnswer ?? DriverLoad.fromJson(_loadJson()),
    );
  }

  @override
  Future<ApiResult<DriverLoad>> closeLoad({required String loadOrder}) async {
    closes.add(loadOrder);
    return ApiResult.success(
      data: closeAnswer ?? DriverLoad.fromJson(_loadJson()),
    );
  }
}

/// The sell screen names the place a sale was made at (delivery_sdk 1.24.0),
/// so it reads the points-of-interest slice too. This double keeps that slice
/// off the network and away from the platform: van sales is what these tests
/// are about, and a driver who names no place is the case they pin.
class _NoPoints implements DriverPoiRepositoryFacade {
  @override
  Future<ApiResult<List<DriverPoiType>>> types() async =>
      const ApiResult.success(data: <DriverPoiType>[]);

  @override
  Future<ApiResult<List<DriverPoi>>> nearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? type,
    String? shop,
  }) async =>
      const ApiResult.success(data: <DriverPoi>[]);

  @override
  Future<ApiResult<DriverPoiFiling>> create({
    required String label,
    required String type,
    required double latitude,
    required double longitude,
    String? customType,
    String? shop,
    String? address,
    String? note,
    String? ownerFirstName,
    String? ownerLastName,
    String? ownerPhone,
    bool ownerConfirmedUser = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<DriverPoiOwner>> lookupOwner({
    required String phone,
  }) async =>
      const ApiResult.success(data: DriverPoiOwner());

  @override
  Future<ApiResult<DriverPoiShopChoices>> myShops() async =>
      const ApiResult.success(data: DriverPoiShopChoices());

  @override
  Future<ApiResult<List<RouteStopData>>> route({
    double? latitude,
    double? longitude,
    String? type,
    String? shop,
  }) async =>
      const ApiResult.success(data: <RouteStopData>[]);

  @override
  Future<ApiResult<DriverPoiSales>> sales({
    required String poi,
    int limit = 50,
  }) async =>
      const ApiResult.success(data: DriverPoiSales());
}

/// A notifier that never reaches the connectivity plugin.
DriverLoadNotifier _notifier(_FakeLoadRepository repository) =>
    DriverLoadNotifier(repository, isOnline: () async => true);

Widget _host(Widget child, DriverLoadNotifier notifier) => ProviderScope(
      overrides: [
        driverLoadProvider.overrideWith((ref) => notifier),
        driverPoiProvider.overrideWith(
          (ref) => DriverPoiNotifier(
            _NoPoints(),
            isOnline: () async => true,
            locationFix: () async =>
                const CourierLocationResult.unavailable(
              denial: CourierLocationDenial.permissionDenied,
              detail: 'load screens: no platform channel under test',
            ),
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 900),
        builder: (context, _) => MaterialApp(home: child),
      ),
    );

Future<DriverLoadNotifier> _pump(
  WidgetTester tester,
  Widget child, {
  required _FakeLoadRepository repository,
  bool preload = true,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final notifier = _notifier(repository);
  if (preload) await notifier.load();
  await tester.pumpWidget(_host(child, notifier));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return notifier;
}

/// Every rendered string, joined, lower-cased.
String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n')
    .toLowerCase();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppStyle.isDark = true);

  group('/load - the list', () {
    testWidgets('no load is one plain sentence and no call to action',
        (tester) async {
      final repository = _FakeLoadRepository(loads: const []);
      await _pump(tester, const DriverLoadPlane(), repository: repository);

      expect(find.byKey(const Key('driverLoadEmpty')), findsOneWidget);
      final empty = tester.widget<Text>(
        find.byKey(const Key('driverLoadEmpty')),
      );
      expect(empty.data, 'No load issued to you yet');
      // Nothing to act on: the driver cannot issue himself a load.
      expect(find.byKey(const Key('driverLoadCard-LOAD-4')), findsNothing);
      final text = _allText(tester);
      for (final forbidden in const [
        'request a load',
        'take stock',
        'add stock',
      ]) {
        expect(text, isNot(contains(forbidden)));
      }
    });

    testWidgets('before the first answer it never says there is no load',
        (tester) async {
      final repository = _FakeLoadRepository(loads: const [])
        ..gate = Completer<void>();
      await _pump(
        tester,
        const DriverLoadPlane(),
        repository: repository,
        preload: false,
        settle: false,
      );
      await tester.pump();

      final empty = tester.widget<Text>(
        find.byKey(const Key('driverLoadEmpty')),
      );
      expect(empty.data, isNot(contains('No load issued')));
      expect(empty.data, 'Reading your load');

      // Let it land: the sentence is allowed only once an answer has come.
      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('driverLoadEmpty'))).data,
        'No load issued to you yet',
      );
    });

    testWidgets('one load shows the shop, every line and the van value',
        (tester) async {
      final repository = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await _pump(tester, const DriverLoadPlane(), repository: repository);

      expect(find.byKey(const Key('driverLoadCard-LOAD-4')), findsOneWidget);
      expect(find.byKey(const Key('driverLoadEmpty')), findsNothing);

      final text = _allText(tester);
      expect(text, contains('depot north'));
      // Title and unit, as the product line carries them.
      expect(text, contains('still water 5l · bottle'));
      expect(text, contains('ice 2kg · bag'));
      // The four quantities the driver checks his van against.
      for (final label in const ['issued', 'sold', 'returned', 'remaining']) {
        expect(text, contains(label));
      }
      // 6 x 45 + 2 x 20 still on the van.
      final total = tester.widget<Text>(
        find.byKey(const Key('driverLoadRemainingTotal-LOAD-4')),
      );
      expect(total.data, contains('310'));

      // The three actions, in the order a day goes.
      expect(find.byKey(const Key('driverLoadSell-LOAD-4')), findsOneWidget);
      expect(find.byKey(const Key('driverLoadReturn-LOAD-4')), findsOneWidget);
      expect(find.byKey(const Key('driverLoadClose-LOAD-4')), findsOneWidget);
    });

    testWidgets('a closed load is not the driver problem any more',
        (tester) async {
      final json = _loadJson()..['load_status'] = 'Closed';
      final repository =
          _FakeLoadRepository(loads: [DriverLoad.fromJson(json)]);
      await _pump(tester, const DriverLoadPlane(), repository: repository);

      expect(find.byKey(const Key('driverLoadCard-LOAD-4')), findsNothing);
      expect(find.byKey(const Key('driverLoadEmpty')), findsOneWidget);
    });
  });

  group('/load/sell', () {
    testWidgets('the total is struck at the load own unit prices',
        (tester) async {
      final repository = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await _pump(
        tester,
        const LoadSalePlane(loadOrder: 'LOAD-4'),
        repository: repository,
      );

      expect(
        tester.widget<Text>(find.byKey(const Key('loadSaleTotal'))).data,
        contains('0'),
      );

      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('loadStepPlus-STK-2')));
      await tester.pump();

      // 2 x 45 + 1 x 20.
      expect(
        tester.widget<Text>(find.byKey(const Key('loadSaleTotal'))).data,
        contains('110'),
      );
    });

    testWidgets('the stepper stops at the server remaining figure',
        (tester) async {
      final repository = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await _pump(
        tester,
        const LoadSalePlane(loadOrder: 'LOAD-4'),
        repository: repository,
      );

      // STK-2 has 2 left; ask for five.
      for (var i = 0; i < 5; i++) {
        final plus = find.byKey(const Key('loadStepPlus-STK-2'));
        if (tester.widget<IconButton>(plus).onPressed == null) break;
        await tester.tap(plus);
        await tester.pump();
      }

      expect(
        tester.widget<Text>(find.byKey(const Key('loadStepQty-STK-2'))).data,
        '2',
      );
      // At the cap the plus is inert rather than complaining.
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('loadStepPlus-STK-2')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('the customer is the walk-in on his own account',
        (tester) async {
      final repository = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await _pump(
        tester,
        const LoadSalePlane(loadOrder: 'LOAD-4'),
        repository: repository,
      );

      expect(find.byKey(const Key('loadSaleCustomer')), findsOneWidget);
      expect(_allText(tester), contains('myself walk in'));
    });

    testWidgets('confirm sends the picked lines and shows the receipt',
        (tester) async {
      final repository = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      )..saleAnswer = DriverLoad.fromJson(_loadJson());
      await _pump(
        tester,
        const LoadSalePlane(loadOrder: 'LOAD-4'),
        repository: repository,
      );

      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('loadSaleConfirm')));
      await tester.pumpAndSettle();

      expect(repository.sales, hasLength(1));
      final (loadOrder, items, customer, _, _) = repository.sales.single;
      expect(loadOrder, 'LOAD-4');
      expect(items.single.stockId, 'STK-1');
      expect(items.single.quantity, 2);
      // No customer: the server books it on the driver's own account.
      expect(customer, isNull);

      expect(find.byKey(const Key('loadSaleDoneSheet')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('loadSaleDoneOrderId')))
            .data,
        contains('ORD-77'),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('loadSaleDoneAmount'))).data,
        contains('90'),
      );
    });

    testWidgets('a load the slice does not hold shows the notice',
        (tester) async {
      final repository = _FakeLoadRepository(loads: const []);
      await _pump(
        tester,
        const LoadSalePlane(loadOrder: 'LOAD-NOPE'),
        repository: repository,
      );

      expect(find.byKey(const Key('loadMissingNotice')), findsOneWidget);
      expect(find.byKey(const Key('loadSaleConfirm')), findsNothing);
    });
  });

  group('/load/return', () {
    testWidgets('sends the picked lines and never shows a money figure',
        (tester) async {
      final repository = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await _pump(
        tester,
        const LoadReturnPlane(loadOrder: 'LOAD-4'),
        repository: repository,
      );

      expect(find.byKey(const Key('loadSaleTotal')), findsNothing);

      await tester.tap(find.byKey(const Key('loadStepPlus-STK-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('loadReturnConfirm')));
      await tester.pump();

      expect(repository.returns, hasLength(1));
      final (loadOrder, items) = repository.returns.single;
      expect(loadOrder, 'LOAD-4');
      expect(items.single.stockId, 'STK-2');
      expect(items.single.quantity, 1);
    });

    testWidgets('it says what happens to what he does not return',
        (tester) async {
      final repository = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await _pump(
        tester,
        const LoadReturnPlane(loadOrder: 'LOAD-4'),
        repository: repository,
      );

      expect(_allText(tester), contains('charged to your wallet'));
    });
  });

  group('close load', () {
    testWidgets('the confirm states the charge before the button',
        (tester) async {
      final load = DriverLoad.fromJson(_loadJson());
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 900),
          builder: (context, _) => MaterialApp(
            home: LoadCloseConfirmDialog(load: load),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = _allText(tester);
      expect(
        text,
        contains(
          'anything not sold and not returned is charged to your wallet at '
          'the load price',
        ),
      );
      // And what that would come to right now: 6 x 45 + 2 x 20.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('loadCloseConfirmFigure')))
            .data,
        contains('310'),
      );
      expect(find.byKey(const Key('loadCloseAgree')), findsOneWidget);
      expect(find.byKey(const Key('loadCloseCancel')), findsOneWidget);
    });

    testWidgets('the summary reads the variance off the server answer',
        (tester) async {
      final closed = DriverLoad.fromJson({
        'id': 'LOAD-4',
        'load_status': 'Closed',
        'variance_amount': 90,
        'lines': [
          {
            'stock_id': 'STK-1',
            'unit_price': 45,
            'variance_qty': 2,
            'variance_amount': 90,
            'product': {'translation': {'title': 'Still water 5L'}},
          },
        ],
      });
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 900),
          builder: (context, _) => MaterialApp(
            home: Scaffold(body: LoadCloseSummarySheet(load: closed)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_allText(tester), contains('still water 5l'));
      expect(
        tester
            .widget<Text>(find.byKey(const Key('loadCloseVarianceTotal')))
            .data,
        contains('90'),
      );
    });

    testWidgets('a load that came back whole says so', (tester) async {
      final closed = DriverLoad.fromJson({
        'id': 'LOAD-4',
        'load_status': 'Closed',
        'lines': [
          {'stock_id': 'STK-1', 'unit_price': 45, 'variance_qty': 0},
        ],
      });
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 900),
          builder: (context, _) => MaterialApp(
            home: Scaffold(body: LoadCloseSummarySheet(load: closed)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loadCloseNoVariance')), findsOneWidget);
      expect(
        find.byKey(const Key('loadCloseVarianceTotal')),
        findsNothing,
      );
    });
  });

  group('the home tile', () {
    testWidgets('names the load and the value still on the van',
        (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 900),
          builder: (context, _) => MaterialApp(
            home: Scaffold(
              body: MyLoadCard(
                remainingUnits: 8,
                remainingValue: 310,
                loadCount: 1,
                onOpen: () => opened++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('driverHomeMyLoadValue')))
            .data,
        contains('310'),
      );
      expect(_allText(tester), contains('on the van'));

      await tester.tap(find.byKey(const Key('driverHomeMyLoadCard')));
      await tester.pump();
      expect(opened, 1);
    });
  });
}
