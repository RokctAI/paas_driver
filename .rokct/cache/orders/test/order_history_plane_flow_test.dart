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
// ORDER HISTORY ON PLANES at the three widths the plane model names
// (approved 38a/38d, Ray 2026-08-30 12:23Z; the bare trailing plane is the
// 10:47Z rule 38b draws for the sibling list):
//
//   * 1280 (three planes): the list declares 2 and holds planes 1–2 in two
//     plane-aligned columns, the third plane TRAILS BARE; a tap pushes the
//     detail into the LAST plane and the list compresses to one column;
//     the corner pill pops it and the spread is restored;
//   * 800 (two planes, the fold): the list fills the screen exactly; a tap
//     yields plane 2 to the detail;
//   * 393 (one plane): the host's compact branch — the list body alone,
//     one column, the tap handed to the shipped bottom sheet.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/adaptive/adaptive_shell.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/components/lists/list_plane_flow.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/application/orders/canceled/canceled_orders_notifier.dart';
import 'package:orders_sdk/src/manager/application/orders/canceled/canceled_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/delivered/delivered_orders_notifier.dart';
import 'package:orders_sdk/src/manager/application/orders/delivered/delivered_orders_provider.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/history/order_history_list.dart';
import 'package:orders_sdk/src/manager/presentation/history/order_history_plane_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSellerOrders implements SellerOrdersRepositoryFacade {
  @override
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    String? rawStatus,
    int? page,
    String? from,
    String? to,
  }) async {
    final bool canceled = status == OrderStatus.canceled;
    return ApiResult.success(
      data: OrdersPaginateResponse(
        data: OrderResponseData(
          statistic: OrdersStatistic(
            deliveredOrdersCount: 4,
            cancelOrdersCount: 1,
          ),
          orders: [
            for (var i = 1; i <= (canceled ? 1 : 4); i++)
              OrderData(
                id: '${canceled ? 'c' : 'd'}-$i',
                status: canceled ? 'canceled' : 'delivered',
                totalPrice: 120,
                deliveryType: 'delivery',
                createdAt: '2026-08-30T10:00:00Z',
                updatedAt: '2026-08-30T10:23:00Z',
                user: UserData(firstname: 'Naledi', lastname: 'M'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  Widget scoped(Size size, Widget body) => ProviderScope(
    overrides: [
      deliveredOrdersProvider.overrideWith(
        (ref) => DeliveredOrdersNotifier(_FakeSellerOrders()),
      ),
      canceledOrdersProvider.overrideWith(
        (ref) => CanceledOrdersNotifier(_FakeSellerOrders()),
      ),
    ],
    child: ScreenUtilInit(
      designSize: size,
      builder: (_, __) => MaterialApp(home: Scaffold(body: body)),
    ),
  );

  /// The installed page's wide branch, the detail pane drawing a marker
  /// where the host draws the shipped OrderDetailsModal.
  Widget flow() => OrderHistoryPlaneFlow(
    backIcon: Icons.arrow_back,
    detailBuilder: (context, order) => Text('DETAIL-${order.id}'),
  );

  /// The Planes the list body was granted, read off the header's context.
  Planes listPlanes(WidgetTester tester) =>
      Planes.of(tester.element(find.byType(OrderHistoryList)));

  Planes detailPlanes(WidgetTester tester) =>
      Planes.of(tester.element(find.byType(OrderHistoryDetailPane)));

  Future<void> pumpAt(WidgetTester tester, Size size, Widget body) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(scoped(size, body));
    await tester.pumpAndSettle();
  }

  testWidgets(
      '1280 (three planes): the list declares 2 over planes 1–2 in two '
      'columns, the third plane trails BARE; a tap pushes the detail into '
      'the LAST plane, the pill pops it and the spread returns',
      (tester) async {
    await pumpAt(tester, const Size(1280, 800), flow());

    var planes = listPlanes(tester);
    expect(planes.count, 3);
    expect(planes.index, 0);
    expect(planes.span, 2);
    // The leftover plane trails bare — the list does not stretch into it.
    expect(planes.isLast, isFalse);
    expect(planes.count - planes.span, 1);
    expect(
      ListPlaneColumns.columnsOf(tester.element(find.byType(OrderHistoryList))),
      2,
    );
    expect(find.byType(FloatingBackPill), findsNothing);
    expect(find.byType(OrderHistoryDetailPane), findsNothing);

    await tester.tap(find.text('№d-2'));
    await tester.pumpAndSettle();

    // Newest wins: the detail takes the LAST plane with the default claim.
    expect(find.text('DETAIL-d-2'), findsOneWidget);
    final detail = detailPlanes(tester);
    expect(detail.index, 2);
    expect(detail.span, 1);
    expect(detail.isLast, isTrue);
    // The list keeps its two planes beside it — no bare stage left.
    planes = listPlanes(tester);
    expect(planes.index, 0);
    expect(planes.span, 2);
    expect(find.byType(FloatingBackPill), findsOneWidget);

    await tester.tap(find.byType(FloatingBackPill));
    await tester.pumpAndSettle();
    expect(find.byType(OrderHistoryDetailPane), findsNothing);
    expect(find.byType(FloatingBackPill), findsNothing);
    expect(listPlanes(tester).span, 2);
  });

  testWidgets(
      '800 (two planes, the fold): the list fills both planes exactly; a '
      'tap yields plane 2 to the detail and the list compresses to one '
      'column; back restores', (tester) async {
    await pumpAt(tester, const Size(800, 1280), flow());

    var planes = listPlanes(tester);
    expect(planes.count, 2);
    expect(planes.span, 2);
    expect(planes.isLast, isTrue);
    expect(find.byType(FloatingBackPill), findsNothing);

    await tester.tap(find.text('№d-1'));
    await tester.pumpAndSettle();

    expect(find.text('DETAIL-d-1'), findsOneWidget);
    final detail = detailPlanes(tester);
    expect(detail.index, 1);
    expect(detail.span, 1);
    planes = listPlanes(tester);
    expect(planes.index, 0);
    expect(planes.span, 1);
    expect(
      ListPlaneColumns.columnsOf(tester.element(find.byType(OrderHistoryList))),
      1,
    );
    expect(find.byType(FloatingBackPill), findsOneWidget);

    // Tapping another card swaps the pane, one detail at a time.
    await tester.tap(find.text('№d-3'));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL-d-3'), findsOneWidget);
    expect(find.text('DETAIL-d-1'), findsNothing);

    await tester.tap(find.byType(FloatingBackPill));
    await tester.pumpAndSettle();
    expect(find.byType(OrderHistoryDetailPane), findsNothing);
    expect(listPlanes(tester).span, 2);
  });

  testWidgets(
      '393 (one plane, 38d): the host picks its compact branch — the list '
      'alone in one column, the tap handed to the shipped sheet',
      (tester) async {
    OrderData? sheetOrder;
    // The installed page's AdaptiveShell mapping: compact = the phone
    // list + sheet, medium/expanded = the plane flow.
    await pumpAt(
      tester,
      const Size(393, 852),
      AdaptiveShell(
        compact: (context) => OrderHistoryList(
          compact: true,
          onOpenDetail: (order, status) => sheetOrder = order,
        ),
        medium: (context) => flow(),
        expanded: (context) => flow(),
      ),
    );

    expect(find.byType(OrderHistoryPlaneFlow), findsNothing);
    expect(find.byType(OrderHistoryList), findsOneWidget);
    expect(
      ListPlaneColumns.columnsOf(tester.element(find.byType(OrderHistoryList))),
      1,
    );
    expect(find.byType(FloatingBackPill), findsNothing);

    await tester.tap(find.text('№d-1'));
    await tester.pumpAndSettle();
    expect(sheetOrder?.id, 'd-1');
    expect(find.byType(OrderHistoryDetailPane), findsNothing);
  });
}
