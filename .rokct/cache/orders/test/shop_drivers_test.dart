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

// THE SHOP'S OWN-DRIVER ROSTER, the manager side.
//
// What is pinned here is what the roster COSTS the shop to get wrong,
// because the roster is not a label — it decides who may be issued a load:
//
//   * the ROW SHAPE the three zones endpoints answer, including a row the
//     shop has retired, which stays on the list and stops counting;
//   * the add flow's candidate list — the platform pool minus whoever is
//     already on, narrowed by a search that matches the login as well as
//     the name, because a shop may only know a driver by his login;
//   * that a write is never guessed at: a refusal leaves the roster
//     exactly as it was and says so, and a success is RE-READ;
//   * that removing is confirmed and the confirmation names what stops
//     working;
//   * the "Manage drivers" action on the issue-a-load screen, and that the
//     driver picker is refetched when it comes back.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/components/lists/list_language.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/application/drivers/shop_drivers_notifier.dart';
import 'package:orders_sdk/src/manager/application/drivers/shop_drivers_provider.dart';
import 'package:orders_sdk/src/manager/application/drivers/shop_drivers_state.dart';
import 'package:orders_sdk/src/manager/application/loads/issue_load_notifier.dart';
import 'package:orders_sdk/src/manager/application/loads/issue_load_provider.dart';
import 'package:orders_sdk/src/manager/domain/interface/shop_drivers.dart';
import 'package:orders_sdk/src/manager/domain/interface/shop_loads.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/drivers/shop_drivers_body.dart';
import 'package:orders_sdk/src/manager/presentation/loads/issue_load_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One roster row exactly as `list_shop_drivers` spells it.
Map<String, dynamic> _driverJson({
  String deliveryman = 'thabo@shop',
  String fullName = 'Thabo N',
  Object? active = 1,
}) => {'deliveryman': deliveryman, 'full_name': fullName, 'active': active};

/// The roster endpoints, recording what was asked of each.
class _FakeShopDrivers implements ShopDriversRepositoryFacade {
  List<Map<String, dynamic>> rows = [];
  final List<String> added = [];
  final List<String> removed = [];
  int listCalls = 0;

  /// Both writes refuse when this is false, the way a backend that has no
  /// such method (or refuses the driver) lands.
  bool writesSucceed = true;

  @override
  Future<ApiResult<List<ShopDriver>>> listShopDrivers() async {
    listCalls++;
    return ApiResult.success(
      data: [for (final r in rows) ShopDriver.fromJson(r)],
    );
  }

  @override
  Future<ApiResult<bool>> addShopDriver({required String deliveryman}) async {
    added.add(deliveryman);
    if (!writesSucceed) {
      return ApiResult.failure(error: 'refused', statusCode: 417);
    }
    rows = [...rows, _driverJson(deliveryman: deliveryman, fullName: '')];
    return ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<bool>> removeShopDriver({
    required String deliveryman,
  }) async {
    removed.add(deliveryman);
    if (!writesSucceed) {
      return ApiResult.failure(error: 'refused', statusCode: 417);
    }
    rows = rows.where((r) => r['deliveryman'] != deliveryman).toList();
    return ApiResult.success(data: true);
  }
}

/// Only `listShopDeliverymen` matters here: it is the pool the add flow
/// draws from. Everything else on the loads facade throws if touched, so a
/// test that reaches for it fails loudly instead of quietly passing.
class _FakeLoadsPool implements ShopLoadsRepositoryFacade {
  List<LoadDeliveryman> drivers;
  int listCalls = 0;
  bool fails = false;

  _FakeLoadsPool({this.drivers = const []});

  @override
  Future<ApiResult<List<LoadDeliveryman>>> listShopDeliverymen() async {
    listCalls++;
    if (fails) {
      return ApiResult.failure(error: 'no such method', statusCode: 404);
    }
    return ApiResult.success(data: drivers);
  }

  @override
  Future<ApiResult<List<LoadData>>> getShopLoads({String? status}) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<LoadData>> createLoad({
    required String deliveryman,
    required List<LoadIssueLine> items,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<LoadData>> closeLoad({required String loadOrder}) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  group('the roster payload', () {
    test('reads the three keys the endpoint answers', () {
      final driver = ShopDriver.fromJson(_driverJson());
      expect(driver.id, 'thabo@shop');
      expect(driver.name, 'Thabo N');
      expect(driver.active, isTrue);
    });

    test('a driver with no full name falls back to the user id', () {
      expect(ShopDriver.fromJson(_driverJson(fullName: '')).name, 'thabo@shop');
    });

    test('active reads 0, false and a missing key the same way it reads 1', () {
      expect(ShopDriver.fromJson(_driverJson(active: 0)).active, isFalse);
      expect(ShopDriver.fromJson(_driverJson(active: false)).active, isFalse);
      expect(ShopDriver.fromJson(_driverJson(active: true)).active, isTrue);
      expect(ShopDriver.fromJson(_driverJson(active: '1')).active, isTrue);
      // A backend that stops sending the flag has not retired anybody.
      expect(
        ShopDriver.fromJson({
          'deliveryman': 'thabo@shop',
          'full_name': 'Thabo N',
        }).active,
        isTrue,
      );
    });
  });

  group('the add flow candidate list', () {
    ShopDriversState stateWith({
      List<ShopDriver> drivers = const [],
      List<LoadDeliveryman> candidates = const [],
      String query = '',
    }) => ShopDriversState(
      drivers: drivers,
      candidates: candidates,
      query: query,
    );

    const pool = [
      LoadDeliveryman(id: 'thabo@shop', name: 'Thabo N'),
      LoadDeliveryman(id: 'lerato@shop', name: 'Lerato K'),
      LoadDeliveryman(id: 'sipho@shop', name: 'Sipho D'),
    ];

    test('a driver already on the roster is not offered again', () {
      final state = stateWith(
        drivers: const [ShopDriver(id: 'thabo@shop', name: 'Thabo N')],
        candidates: pool,
      );
      expect(state.addableCandidates.map((d) => d.id), [
        'lerato@shop',
        'sipho@shop',
      ]);
    });

    test('a RETIRED row still blocks a re-add, because the row is there', () {
      final state = stateWith(
        drivers: const [
          ShopDriver(id: 'thabo@shop', name: 'Thabo N', active: false),
        ],
        candidates: pool,
      );
      expect(
        state.addableCandidates.map((d) => d.id),
        isNot(contains('thabo@shop')),
      );
    });

    test('the search matches the name AND the login', () {
      expect(
        stateWith(candidates: pool, query: 'ler').addableCandidates.single.id,
        'lerato@shop',
      );
      expect(
        stateWith(
          candidates: pool,
          query: 'SIPHO@',
        ).addableCandidates.single.id,
        'sipho@shop',
      );
      expect(
        stateWith(candidates: pool, query: '  ').addableCandidates,
        hasLength(3),
      );
      expect(
        stateWith(candidates: pool, query: 'zz').addableCandidates,
        isEmpty,
      );
    });

    test('activeDrivers counts only what the shop still keeps', () {
      final state = stateWith(
        drivers: const [
          ShopDriver(id: 'a@shop', name: 'A'),
          ShopDriver(id: 'b@shop', name: 'B', active: false),
        ],
      );
      expect(state.activeDrivers.map((d) => d.id), ['a@shop']);
      expect(state.drivers, hasLength(2));
    });
  });

  group('the notifier - a write is never guessed at', () {
    ShopDriversNotifier build(_FakeShopDrivers roster, _FakeLoadsPool pool) =>
        ShopDriversNotifier(roster, pool);

    test('a successful add RE-READS the roster', () async {
      final roster = _FakeShopDrivers()..rows = [_driverJson()];
      final notifier = build(roster, _FakeLoadsPool());
      await notifier.fetchDrivers();
      expect(roster.listCalls, 1);

      expect(await notifier.addDriver('lerato@shop'), isTrue);
      expect(roster.added, ['lerato@shop']);
      expect(roster.listCalls, 2);
      expect(notifier.state.drivers.map((d) => d.id), [
        'thabo@shop',
        'lerato@shop',
      ]);
      expect(notifier.state.pendingId, isNull);
    });

    test('a refused add leaves the roster exactly as it was', () async {
      final roster = _FakeShopDrivers()
        ..rows = [_driverJson()]
        ..writesSucceed = false;
      final notifier = build(roster, _FakeLoadsPool());
      await notifier.fetchDrivers();

      expect(await notifier.addDriver('lerato@shop'), isFalse);
      expect(notifier.state.drivers.map((d) => d.id), ['thabo@shop']);
      // No re-read on a refusal: there is nothing new to read.
      expect(roster.listCalls, 1);
      expect(notifier.state.pendingId, isNull);
    });

    test('a successful remove takes the row off and re-reads', () async {
      final roster = _FakeShopDrivers()
        ..rows = [_driverJson(), _driverJson(deliveryman: 'lerato@shop')];
      final notifier = build(roster, _FakeLoadsPool());
      await notifier.fetchDrivers();

      expect(await notifier.removeDriver('thabo@shop'), isTrue);
      expect(roster.removed, ['thabo@shop']);
      expect(notifier.state.drivers.map((d) => d.id), ['lerato@shop']);
    });

    test('a refused remove keeps the driver on the roster', () async {
      final roster = _FakeShopDrivers()
        ..rows = [_driverJson()]
        ..writesSucceed = false;
      final notifier = build(roster, _FakeLoadsPool());
      await notifier.fetchDrivers();

      expect(await notifier.removeDriver('thabo@shop'), isFalse);
      expect(notifier.state.drivers.map((d) => d.id), ['thabo@shop']);
    });

    test('a failed read is a failure, not an empty roster', () async {
      final roster = _FakeShopDrivers();
      final notifier = ShopDriversNotifier(_FailingRoster(), _FakeLoadsPool());
      await notifier.fetchDrivers();
      expect(notifier.state.hasFailed, isTrue);
      expect(notifier.state.drivers, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(roster.listCalls, 0);
    });

    test('candidates come from the LOAD module pool, and a failure there '
        'leaves the list empty rather than stuck loading', () async {
      final pool = _FakeLoadsPool(
        drivers: const [LoadDeliveryman(id: 'lerato@shop', name: 'Lerato K')],
      );
      final notifier = build(_FakeShopDrivers(), pool);
      await notifier.fetchCandidates();
      expect(pool.listCalls, 1);
      expect(notifier.state.candidates.single.id, 'lerato@shop');

      pool.fails = true;
      await notifier.fetchCandidates();
      expect(notifier.state.isLoadingCandidates, isFalse);
    });
  });

  group('the roster screen', () {
    Future<_FakeShopDrivers> pumpRoster(
      WidgetTester tester, {
      List<Map<String, dynamic>> rows = const [],
      bool writesSucceed = true,
      List<LoadDeliveryman> pool = const [],
      Future<void> Function(BuildContext)? openAddFlow,
    }) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final roster = _FakeShopDrivers()
        ..rows = [...rows]
        ..writesSucceed = writesSucceed;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopDriversProvider.overrideWith(
              (ref) =>
                  ShopDriversNotifier(roster, _FakeLoadsPool(drivers: pool)),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: ShopDriversBody(compact: true, openAddFlow: openAddFlow),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return roster;
    }

    testWidgets('draws the roster, the count and what a roster DOES', (
      tester,
    ) async {
      await pumpRoster(
        tester,
        rows: [
          _driverJson(),
          _driverJson(deliveryman: 'lerato@shop', fullName: 'Lerato K'),
        ],
      );
      expect(find.text('Thabo N'), findsOneWidget);
      expect(find.text('Lerato K'), findsOneWidget);
      expect(find.text('2 drivers'), findsOneWidget);
      // The consequence of the roster is on the screen, not in a help sheet.
      expect(
        find.textContaining('can only load those drivers'),
        findsOneWidget,
      );
      expect(find.byType(ListRoundAction), findsOneWidget);
    });

    testWidgets('an empty roster says so and still offers the one action', (
      tester,
    ) async {
      await pumpRoster(tester);
      expect(find.text('No own drivers yet'), findsOneWidget);
      expect(find.text('0 drivers'), findsOneWidget);
      expect(find.byType(ListRoundAction), findsOneWidget);
    });

    testWidgets('a retired row keeps its place and stops counting', (
      tester,
    ) async {
      await pumpRoster(
        tester,
        rows: [
          _driverJson(),
          _driverJson(deliveryman: 'x@shop', active: 0),
        ],
      );
      expect(find.byType(ShopDriverRow), findsNWidgets(2));
      expect(find.text('1 drivers'), findsOneWidget);
      expect(find.textContaining('Retired'), findsOneWidget);
    });

    testWidgets('removing is confirmed, and cancelling removes nothing', (
      tester,
    ) async {
      final roster = await pumpRoster(tester, rows: [_driverJson()]);
      await tester.tap(find.byIcon(Icons.person_remove_alt_1));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // The confirmation names what stops working.
      expect(find.textContaining('no longer be issued a load'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(roster.removed, isEmpty);
      expect(find.text('Thabo N'), findsOneWidget);
    });

    testWidgets('confirming removes the driver and says so', (tester) async {
      final roster = await pumpRoster(tester, rows: [_driverJson()]);
      await tester.tap(find.byIcon(Icons.person_remove_alt_1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove driver'));
      await tester.pumpAndSettle();

      expect(roster.removed, ['thabo@shop']);
      expect(find.text('Thabo N'), findsNothing);
      expect(find.text('Driver removed'), findsOneWidget);
    });

    testWidgets('a refused remove keeps him and says THAT', (tester) async {
      final roster = await pumpRoster(
        tester,
        rows: [_driverJson()],
        writesSucceed: false,
      );
      await tester.tap(find.byIcon(Icons.person_remove_alt_1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove driver'));
      await tester.pumpAndSettle();

      expect(roster.removed, ['thabo@shop']);
      expect(find.text('Thabo N'), findsOneWidget);
      expect(find.text('Could not remove driver'), findsOneWidget);
    });

    testWidgets('a roster that cannot be read says so instead of showing '
        'an empty list', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopDriversProvider.overrideWith(
              (ref) => ShopDriversNotifier(_FailingRoster(), _FakeLoadsPool()),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => const MaterialApp(
              home: Scaffold(body: ShopDriversBody(compact: true)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not read your drivers'), findsOneWidget);
      expect(find.text('No own drivers yet'), findsNothing);
    });

    testWidgets('the header action opens the add flow', (tester) async {
      int opened = 0;
      await pumpRoster(tester, openAddFlow: (context) async => opened++);
      await tester.tap(find.byType(ListRoundAction));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });
  });

  group('the add flow', () {
    Future<_FakeShopDrivers> pumpAdd(
      WidgetTester tester, {
      List<Map<String, dynamic>> rows = const [],
      List<LoadDeliveryman> pool = const [],
      bool writesSucceed = true,
    }) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final roster = _FakeShopDrivers()
        ..rows = [...rows]
        ..writesSucceed = writesSucceed;
      // The sheet never reads the roster itself: in the app it opens OVER
      // the roster body, which has already read it, and reading it twice
      // for every sheet would be a round trip for nothing. So the harness
      // primes the notifier the same way the body does, then hands that
      // instance to the override.
      final notifier = ShopDriversNotifier(
        roster,
        _FakeLoadsPool(drivers: pool),
      );
      await notifier.fetchDrivers();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [shopDriversProvider.overrideWith((ref) => notifier)],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) =>
                const MaterialApp(home: Scaffold(body: AddShopDriverSheet())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return roster;
    }

    testWidgets('lists the platform pool minus who is already on', (
      tester,
    ) async {
      await pumpAdd(
        tester,
        rows: [_driverJson()],
        pool: const [
          LoadDeliveryman(id: 'thabo@shop', name: 'Thabo N'),
          LoadDeliveryman(id: 'lerato@shop', name: 'Lerato K'),
        ],
      );
      expect(find.text('Lerato K'), findsOneWidget);
      expect(find.text('Thabo N'), findsNothing);
    });

    testWidgets('tapping one adds him', (tester) async {
      final roster = await pumpAdd(
        tester,
        pool: const [LoadDeliveryman(id: 'lerato@shop', name: 'Lerato K')],
      );
      await tester.tap(find.text('Lerato K'));
      await tester.pumpAndSettle();
      expect(roster.added, ['lerato@shop']);
    });

    testWidgets('a refused add says so and adds nobody', (tester) async {
      final roster = await pumpAdd(
        tester,
        pool: const [LoadDeliveryman(id: 'lerato@shop', name: 'Lerato K')],
        writesSucceed: false,
      );
      await tester.tap(find.text('Lerato K'));
      await tester.pumpAndSettle();
      expect(roster.added, ['lerato@shop']);
      expect(roster.rows, isEmpty);
      expect(find.text('Could not add driver'), findsOneWidget);
    });

    testWidgets('nothing left to add is said plainly', (tester) async {
      // What the backend legitimately answers once a shop HAS a roster:
      // list_shop_deliverymen narrows to it, so the pool and the roster are
      // the same people and there is nobody left to offer.
      await pumpAdd(
        tester,
        rows: [_driverJson()],
        pool: const [LoadDeliveryman(id: 'thabo@shop', name: 'Thabo N')],
      );
      expect(find.text('No drivers left to add'), findsOneWidget);
    });

    testWidgets('the search narrows the pool', (tester) async {
      await pumpAdd(
        tester,
        pool: const [
          LoadDeliveryman(id: 'lerato@shop', name: 'Lerato K'),
          LoadDeliveryman(id: 'sipho@shop', name: 'Sipho D'),
        ],
      );
      await tester.enterText(find.byType(TextField), 'sip');
      await tester.pumpAndSettle();
      expect(find.text('Sipho D'), findsOneWidget);
      expect(find.text('Lerato K'), findsNothing);
    });
  });

  group('the issue-a-load entry point', () {
    testWidgets('"Manage drivers" is drawn and refetches the picker on '
        'return', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final pool = _FakeLoadsPool(
        drivers: const [LoadDeliveryman(id: 'thabo@shop', name: 'Thabo N')],
      );
      int opened = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            issueLoadProvider.overrideWith((ref) => IssueLoadNotifier(pool)),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: IssueLoadBody(
                  pickerBuilder: (context, onPick) => const SizedBox.shrink(),
                  onIssued: (_) {},
                  onManageDrivers: () async => opened++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(pool.listCalls, 1);

      await tester.tap(find.text('Manage drivers'));
      await tester.pumpAndSettle();
      expect(opened, 1);
      // The roster is what the picker lists, so coming back re-reads it.
      expect(pool.listCalls, 2);
    });

    testWidgets('an unwired host draws no action at all', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            issueLoadProvider.overrideWith(
              (ref) => IssueLoadNotifier(_FakeLoadsPool()),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: IssueLoadBody(
                  pickerBuilder: (context, onPick) => const SizedBox.shrink(),
                  onIssued: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Manage drivers'), findsNothing);
    });
  });
}

/// A roster whose read fails, as a tenant without zones' delivery module
/// answers: the method does not resolve.
class _FailingRoster implements ShopDriversRepositoryFacade {
  @override
  Future<ApiResult<List<ShopDriver>>> listShopDrivers() async =>
      ApiResult.failure(error: 'no such method', statusCode: 404);

  @override
  Future<ApiResult<bool>> addShopDriver({required String deliveryman}) async =>
      ApiResult.failure(error: 'no such method', statusCode: 404);

  @override
  Future<ApiResult<bool>> removeShopDriver({
    required String deliveryman,
  }) async => ApiResult.failure(error: 'no such method', statusCode: 404);
}
