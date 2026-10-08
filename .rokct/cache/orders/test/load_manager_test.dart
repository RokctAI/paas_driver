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

// DRIVER CONSIGNMENT LOADS, the manager side (commerce#135).
//
// What is pinned here is the arithmetic that moves money and stock:
//
//   * the VARIANCE — issued minus sold minus returned, priced at the
//     load's own unit price — because closing a load is what charges it
//     to the driver's wallet, and the confirm dialog has to name it
//     BEFORE the shop commits;
//   * the DRAFT on the issue screen — one line per shelf row, never two,
//     never more than the shelf holds, never a zero line on the wire;
//   * the list's per-status buckets, which are what the two tabs count;
//   * the payload the endpoints actually answer, including the one key
//     the list serializer does NOT carry (`closed_at`).

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/components/lists/list_language.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/application/loads/issue_load_notifier.dart';
import 'package:orders_sdk/src/manager/application/loads/issue_load_provider.dart';
import 'package:orders_sdk/src/manager/application/loads/shop_loads_notifier.dart';
import 'package:orders_sdk/src/manager/application/loads/shop_loads_provider.dart';
import 'package:orders_sdk/src/manager/domain/interface/shop_loads.dart';
import 'package:orders_sdk/src/manager/domain/load_draft.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/loads/issue_load_body.dart';
import 'package:orders_sdk/src/manager/presentation/loads/load_detail.dart';
import 'package:orders_sdk/src/manager/presentation/loads/loads_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One serialized load exactly as `_serialize_load` spells it.
Map<String, dynamic> _loadJson({
  required String id,
  required String status,
  String driver = 'driver@shop',
  String driverName = 'Thabo N',
  List<Map<String, dynamic>> lines = const [],
  String? closedAt,
  Map<String, dynamic>? totals,
}) => {
  'id': id,
  'shop': {'id': 'SHOP-1', 'title': 'Corner Store'},
  'deliveryman': {'id': driver, 'name': driverName},
  'load_status': status,
  'created_at': '2026-09-18 06:30:00',
  'lines': lines,
  if (closedAt != null) 'closed_at': closedAt,
  if (totals != null) 'totals': totals,
};

Map<String, dynamic> _lineJson({
  String itemId = 'ITM-1',
  String stockId = 'STK-1',
  String title = 'Maize meal 10kg',
  num unitPrice = 100,
  num issued = 10,
  num sold = 6,
  num returned = 1,
}) => {
  'item_id': itemId,
  'stock_id': stockId,
  'product': {
    'id': 'PRD-1',
    'uuid': 'PRD-1',
    'translation': {'title': title},
    'img': null,
    'unit': 'UNIT-KG',
  },
  'unit_price': unitPrice,
  'issued_qty': issued,
  'sold_qty': sold,
  'returned_qty': returned,
  'remaining_qty': issued - sold - returned,
};

/// Serves the two status buckets their own answers, so the tabs are
/// genuinely independent — and records what each call asked for.
class _FakeShopLoads implements ShopLoadsRepositoryFacade {
  final List<String?> statusesAsked = [];
  final List<LoadDeliveryman> drivers;
  Map<String, dynamic>? createdLoad;
  Map<String, dynamic>? closedLoad;
  String? closedId;
  String? createdFor;
  List<LoadIssueLine> createdItems = const [];

  _FakeShopLoads({this.drivers = const []});

  List<Map<String, dynamic>> open = [];
  List<Map<String, dynamic>> closed = [];

  @override
  Future<ApiResult<List<LoadData>>> getShopLoads({String? status}) async {
    statusesAsked.add(status);
    final rows = status == kLoadStatusClosed ? closed : open;
    return ApiResult.success(data: [for (final r in rows) LoadData.fromJson(r)]);
  }

  @override
  Future<ApiResult<List<LoadDeliveryman>>> listShopDeliverymen() async =>
      ApiResult.success(data: drivers);

  @override
  Future<ApiResult<LoadData>> createLoad({
    required String deliveryman,
    required List<LoadIssueLine> items,
  }) async {
    createdFor = deliveryman;
    createdItems = items;
    return ApiResult.success(data: LoadData.fromJson(createdLoad!));
  }

  @override
  Future<ApiResult<LoadData>> closeLoad({required String loadOrder}) async {
    closedId = loadOrder;
    return ApiResult.success(data: LoadData.fromJson(closedLoad!));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.setSelectedCurrency(
      CurrencyData(id: 'ZAR', symbol: 'R', position: 'before', rate: 1),
    );
  });

  group('the load payload', () {
    test('reads the serialized shape, product title and all', () {
      final load = LoadData.fromJson(
        _loadJson(id: 'LD-1', status: 'open', lines: [_lineJson()]),
      );
      expect(load.id, 'LD-1');
      expect(load.shop?.title, 'Corner Store');
      expect(load.deliveryman?.name, 'Thabo N');
      expect(load.isClosed, isFalse);
      expect(load.createdAt, DateTime(2026, 9, 18, 6, 30));
      expect(load.lines.single.product.title, 'Maize meal 10kg');
      expect(load.lines.single.stockId, 'STK-1');
      expect(load.lines.single.remainingQty, 3);
    });

    test('a driver with no full name falls back to the user id', () {
      final driver = LoadDeliveryman.fromJson({
        'id': 'driver@shop',
        'name': '',
      });
      expect(driver.name, 'driver@shop');
    });

    test('the LIST carries no closed_at, and the surface must not invent '
        'one; the close answer does carry it', () {
      final listed = LoadData.fromJson(
        _loadJson(id: 'LD-2', status: 'closed', lines: [_lineJson()]),
      );
      expect(listed.isClosed, isTrue);
      expect(listed.closedAt, isNull);

      final answered = LoadData.fromJson(
        _loadJson(
          id: 'LD-2',
          status: 'closed',
          lines: [_lineJson()],
          closedAt: '2026-09-18 17:05:00',
          totals: {
            'issued_qty': 10,
            'sold_qty': 6,
            'returned_qty': 1,
            'variance_qty': 3,
            'variance_amount': 300,
            'variance_charged': 300,
          },
        ),
      );
      expect(answered.closedAt, DateTime(2026, 9, 18, 17, 5));
      expect(answered.totals?.varianceCharged, 300);
      expect(answered.alreadyClosed, isFalse);
    });
  });

  group('variance - what closing charges the driver', () {
    test('issued minus sold minus returned, at the LOAD unit price', () {
      final load = LoadData.fromJson(
        _loadJson(
          id: 'LD-3',
          status: 'open',
          lines: [
            _lineJson(unitPrice: 100, issued: 10, sold: 6, returned: 1),
            _lineJson(
              itemId: 'ITM-2',
              stockId: 'STK-2',
              title: 'Sugar 2kg',
              unitPrice: 40,
              issued: 5,
              sold: 5,
              returned: 0,
            ),
          ],
        ),
      );
      expect(load.lines.first.varianceQty, 3);
      expect(load.lines.first.varianceAmount, 300);
      // A line fully sold owes nothing.
      expect(load.lines.last.varianceQty, 0);
      expect(load.lines.last.varianceAmount, 0);
      expect(load.varianceQty, 3);
      expect(load.varianceAmount, 300);
      expect(load.issuedQty, 15);
      expect(load.remainingQty, 3);
    });

    test('an over-return is never a credit', () {
      final line = LoadLine.fromJson(
        _lineJson(unitPrice: 100, issued: 4, sold: 2, returned: 5)
          ..remove('remaining_qty'),
      );
      expect(line.varianceQty, 0);
      expect(line.varianceAmount, 0);
      expect(line.remainingQty, 0);
    });
  });

  group('the list buckets', () {
    test('a bucket only ever holds the status it asked for', () {
      final rows = [
        LoadData.fromJson(_loadJson(id: 'LD-1', status: 'open')),
        LoadData.fromJson(_loadJson(id: 'LD-2', status: 'closed')),
      ];
      expect(
        filterLoadsByStatus(rows, kLoadStatusOpen).map((l) => l.id),
        ['LD-1'],
      );
      expect(
        filterLoadsByStatus(rows, kLoadStatusClosed).map((l) => l.id),
        ['LD-2'],
      );
      expect(filterLoadsByStatus(rows, null).length, 2);
    });

    test('each status is fetched through its own get_shop_loads(status)',
        () async {
      final repo = _FakeShopLoads()
        ..open = [_loadJson(id: 'LD-1', status: 'open')]
        ..closed = [_loadJson(id: 'LD-2', status: 'closed')];
      final notifier = ShopLoadsNotifier(repo);
      await notifier.fetchLoads();
      expect(repo.statusesAsked, containsAll(<String>['open', 'closed']));
      expect(notifier.state.openLoads.single.id, 'LD-1');
      expect(notifier.state.closedLoads.single.id, 'LD-2');
      expect(notifier.state.isLoading, isFalse);
    });

    test('closing moves the load from the open bucket to the closed one',
        () async {
      final repo = _FakeShopLoads()
        ..open = [_loadJson(id: 'LD-1', status: 'open', lines: [_lineJson()])]
        ..closedLoad = _loadJson(
          id: 'LD-1',
          status: 'closed',
          lines: [_lineJson()],
          closedAt: '2026-09-18 17:05:00',
        );
      final notifier = ShopLoadsNotifier(repo);
      await notifier.fetchLoads();
      expect(notifier.state.openLoads, hasLength(1));

      final closed = await notifier.closeLoad('LD-1');
      expect(repo.closedId, 'LD-1');
      expect(closed?.isClosed, isTrue);
      expect(notifier.state.openLoads, isEmpty);
      expect(notifier.state.closedLoads.first.id, 'LD-1');
      expect(notifier.state.closingId, isNull);
    });
  });

  group('the issue draft', () {
    LoadDraftLine line({
      String stockId = 'STK-1',
      num unitPrice = 100,
      num available = 8,
      num quantity = 0,
    }) => LoadDraftLine(
      stockId: stockId,
      title: 'Maize meal 10kg',
      unitPrice: unitPrice,
      available: available,
      quantity: quantity,
    );

    test('one line per shelf row, never two', () {
      var lines = <LoadDraftLine>[];
      lines = setDraftQuantity(lines, line(), 2);
      lines = setDraftQuantity(lines, line(), 5);
      expect(lines, hasLength(1));
      expect(lines.single.quantity, 5);
      expect(draftQuantityOf(lines, 'STK-1'), 5);
    });

    test('never more than the shelf holds - issuing is what empties it', () {
      final lines = setDraftQuantity(<LoadDraftLine>[], line(available: 8), 40);
      expect(lines.single.quantity, 8);
    });

    test('dropping to zero (or below) takes the line off the load', () {
      var lines = setDraftQuantity(<LoadDraftLine>[], line(), 3);
      lines = setDraftQuantity(lines, line(), 0);
      expect(lines, isEmpty);
      lines = setDraftQuantity(lines, line(), -4);
      expect(lines, isEmpty);
    });

    test('a shelf row with nothing on it never joins the load', () {
      final lines = setDraftQuantity(
        <LoadDraftLine>[],
        line(available: 0),
        3,
      );
      expect(lines, isEmpty);
    });

    test('the draft values itself at shelf prices and puts only real rows '
        'on the wire', () {
      var lines = setDraftQuantity(<LoadDraftLine>[], line(unitPrice: 100), 3);
      lines = setDraftQuantity(
        lines,
        line(stockId: 'STK-2', unitPrice: 40, available: 10),
        2,
      );
      expect(draftLoadValue(lines), 380);
      final wire = draftIssueLines(lines);
      expect(wire.map((l) => l.stockId), ['STK-1', 'STK-2']);
      expect(wire.first.toJson(), {'stock': 'STK-1', 'quantity': 3});
    });

    test('a load needs a driver AND something on it', () {
      final lines = setDraftQuantity(<LoadDraftLine>[], line(), 1);
      expect(canIssueLoad(deliverymanId: null, lines: lines), isFalse);
      expect(canIssueLoad(deliverymanId: '', lines: lines), isFalse);
      expect(
        canIssueLoad(deliverymanId: 'driver@shop', lines: const []),
        isFalse,
      );
      expect(canIssueLoad(deliverymanId: 'driver@shop', lines: lines), isTrue);
    });

    test('a picked product becomes its shop shelf row', () {
      final product = ProductData(
        id: 'PRD-1',
        uuid: 'PRD-1',
        translation: Translation(title: 'Maize meal 10kg'),
        stocks: [Stock(id: 'STK-1', price: 100, quantity: 8)],
      );
      final drafted = loadDraftLineFromProduct(product);
      expect(drafted?.stockId, 'STK-1');
      expect(drafted?.unitPrice, 100);
      expect(drafted?.available, 8);
      expect(drafted?.title, 'Maize meal 10kg');

      // A product the shop carries no stock row for has nothing to issue.
      expect(
        loadDraftLineFromProduct(ProductData(id: 'PRD-2', stocks: const [])),
        isNull,
      );
    });

    test('issuing sends the driver and the rows, and answers the load',
        () async {
      final repo = _FakeShopLoads(
        drivers: const [LoadDeliveryman(id: 'driver@shop', name: 'Thabo N')],
      )..createdLoad = _loadJson(
        id: 'LD-9',
        status: 'open',
        lines: [_lineJson(issued: 3, sold: 0, returned: 0)],
      );
      final notifier = IssueLoadNotifier(repo);
      await notifier.fetchDrivers();
      // One driver on file is the pick; nothing is guessed when there is a
      // choice to make.
      expect(notifier.state.deliverymanId, 'driver@shop');

      notifier.addProduct(
        ProductData(
          id: 'PRD-1',
          translation: Translation(title: 'Maize meal 10kg'),
          stocks: [Stock(id: 'STK-1', price: 100, quantity: 8)],
        ),
      );
      expect(notifier.state.lines.single.quantity, 1);
      expect(notifier.state.canIssue, isTrue);

      final issued = await notifier.issue();
      expect(repo.createdFor, 'driver@shop');
      expect(repo.createdItems.single.stockId, 'STK-1');
      expect(repo.createdItems.single.quantity, 1);
      expect(issued?.id, 'LD-9');
    });

    test('an empty draft never reaches the wire', () async {
      final repo = _FakeShopLoads();
      final notifier = IssueLoadNotifier(repo);
      notifier.selectDeliveryman('driver@shop');
      expect(await notifier.issue(), isNull);
      expect(repo.createdFor, isNull);
    });
  });

  group('the loads list', () {
    Future<_FakeShopLoads> pumpList(
      WidgetTester tester, {
      void Function()? onIssueLoad,
      void Function(LoadData load)? onOpenDetail,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final repo = _FakeShopLoads()
        ..open = [
          _loadJson(id: 'LD-1', status: 'open', lines: [_lineJson()]),
          _loadJson(
            id: 'LD-3',
            status: 'open',
            driver: 'other@shop',
            driverName: 'Lerato K',
            lines: [_lineJson(itemId: 'ITM-3')],
          ),
        ]
        ..closed = [
          _loadJson(
            id: 'LD-2',
            status: 'closed',
            driverName: 'Sipho D',
            lines: [_lineJson()],
          ),
        ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopLoadsProvider.overrideWith((ref) => ShopLoadsNotifier(repo)),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: LoadsList(
                  compact: true,
                  onIssueLoad: onIssueLoad ?? () {},
                  onOpenDetail: onOpenDetail ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('two status tabs, each counted off its own call', (
      tester,
    ) async {
      final repo = await pumpList(tester);
      expect(repo.statusesAsked, containsAll(<String>['open', 'closed']));
      expect(find.byType(ListFilterTabBar), findsOneWidget);
      expect(find.text('Open loads'), findsOneWidget);
      expect(find.text('Closed loads'), findsOneWidget);
      // The header pill counts both together.
      expect(find.text('3 loads'), findsOneWidget);
    });

    testWidgets('a card names the driver and what is left of what was '
        'issued', (tester) async {
      await pumpList(tester);
      expect(find.text('Thabo N'), findsOneWidget);
      expect(find.text('Lerato K'), findsOneWidget);
      // 10 issued, 6 sold, 1 returned.
      expect(find.text('3 / 10'), findsNWidgets(2));
      expect(find.textContaining('1 lines on load'), findsWidgets);
    });

    testWidgets('selecting Closed swaps the list to the closed bucket', (
      tester,
    ) async {
      await pumpList(tester);
      expect(find.text('Sipho D'), findsNothing);
      await tester.tap(find.text('Closed loads'));
      await tester.pumpAndSettle();
      expect(find.text('Sipho D'), findsOneWidget);
      expect(find.text('Thabo N'), findsNothing);
    });

    testWidgets('tapping a card opens its detail; the header action issues', (
      tester,
    ) async {
      LoadData? opened;
      int issueTaps = 0;
      await pumpList(
        tester,
        onOpenDetail: (load) => opened = load,
        onIssueLoad: () => issueTaps++,
      );
      await tester.tap(find.text('Thabo N'));
      await tester.pumpAndSettle();
      expect(opened?.id, 'LD-1');

      await tester.tap(find.byType(ListRoundAction));
      await tester.pumpAndSettle();
      expect(issueTaps, 1);
    });
  });

  group('the load detail', () {
    Future<_FakeShopLoads> pumpDetail(
      WidgetTester tester,
      Map<String, dynamic> json, {
      Map<String, dynamic>? closeAnswer,
    }) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final repo = _FakeShopLoads()..closedLoad = closeAnswer;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopLoadsProvider.overrideWith((ref) => ShopLoadsNotifier(repo)),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(body: LoadDetail(load: LoadData.fromJson(json))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('an open load draws the four quantity columns and the one '
        'action', (tester) async {
      await pumpDetail(
        tester,
        _loadJson(id: 'LD-1', status: 'open', lines: [_lineJson()]),
      );
      expect(find.text('Issued'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
      expect(find.text('Returned'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Maize meal 10kg'), findsOneWidget);
      expect(find.text('Close load'), findsOneWidget);
    });

    testWidgets('the confirm dialog NAMES the amount the driver will be '
        'charged', (tester) async {
      await pumpDetail(
        tester,
        _loadJson(id: 'LD-1', status: 'open', lines: [_lineJson()]),
      );
      await tester.tap(find.text('Close load'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // 3 short at R100 — the money the shop is about to take off him.
      expect(find.textContaining('300'), findsWidgets);
      expect(
        find.textContaining('charged to the drivers wallet'),
        findsWidgets,
      );
      expect(find.text('Close load and charge'), findsOneWidget);
    });

    testWidgets('nothing missing is said plainly, not as a zero charge', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _loadJson(
          id: 'LD-1',
          status: 'open',
          lines: [_lineJson(issued: 6, sold: 6, returned: 0)],
        ),
      );
      await tester.tap(find.text('Close load'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nothing is missing so nothing is charged'),
        findsOneWidget,
      );
    });

    testWidgets('confirming closes the load and charges it once', (
      tester,
    ) async {
      final repo = await pumpDetail(
        tester,
        _loadJson(id: 'LD-1', status: 'open', lines: [_lineJson()]),
        closeAnswer: _loadJson(
          id: 'LD-1',
          status: 'closed',
          lines: [_lineJson()],
          closedAt: '2026-09-18 17:05:00',
          totals: {
            'issued_qty': 10,
            'sold_qty': 6,
            'returned_qty': 1,
            'variance_qty': 3,
            'variance_amount': 300,
            'variance_charged': 300,
          },
        ),
      );
      await tester.tap(find.text('Close load'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close load and charge'));
      await tester.pumpAndSettle();

      expect(repo.closedId, 'LD-1');
      // A closed load has no action left, and says what it cost.
      expect(find.text('Close load'), findsNothing);
      expect(find.text('Variance'), findsOneWidget);
    });

    testWidgets('a closed load offers no action at all', (tester) async {
      await pumpDetail(
        tester,
        _loadJson(
          id: 'LD-2',
          status: 'closed',
          lines: [_lineJson()],
          closedAt: '2026-09-18 17:05:00',
        ),
      );
      expect(find.text('Close load'), findsNothing);
      expect(find.text('Variance'), findsOneWidget);
      expect(find.textContaining('Closed on'), findsWidgets);
    });
  });

  group('the issue screen', () {
    testWidgets('the driver row and the draft foot drive one create_load', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final repo = _FakeShopLoads(
        drivers: const [
          LoadDeliveryman(id: 'driver@shop', name: 'Thabo N'),
          LoadDeliveryman(id: 'other@shop', name: 'Lerato K'),
        ],
      )..createdLoad = _loadJson(id: 'LD-9', status: 'open');
      LoadData? issued;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shopLoadsProvider.overrideWith((ref) => ShopLoadsNotifier(repo)),
            issueLoadProvider.overrideWith((ref) => IssueLoadNotifier(repo)),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: IssueLoadBody(
                  onIssued: (load) => issued = load,
                  pickerBuilder: (context, onPick) => Center(
                    child: TextButton(
                      onPressed: () => onPick(
                        ProductData(
                          id: 'PRD-1',
                          translation: Translation(title: 'Maize meal 10kg'),
                          stocks: [
                            Stock(id: 'STK-1', price: 100, quantity: 8),
                          ],
                        ),
                      ),
                      child: const Text('pick'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Two drivers on file: the shop chooses, nothing is chosen for it.
      expect(find.text('Thabo N'), findsOneWidget);
      expect(find.text('Lerato K'), findsOneWidget);
      expect(find.text('Tap a product to put it on the load'), findsOneWidget);

      await tester.tap(find.text('Thabo N'));
      await tester.pump();
      await tester.tap(find.text('pick'));
      await tester.pump();
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Load value'), findsOneWidget);
      await tester.tap(find.text('Issue to driver'));
      await tester.pumpAndSettle();

      expect(repo.createdFor, 'driver@shop');
      expect(repo.createdItems.single.quantity, 2);
      expect(issued?.id, 'LD-9');
    });
  });
}
