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

// ORDER HISTORY in the standard list language (approved frames 38a/38d,
// Ray 2026-08-30 12:23Z):
//
//   * the tabs are history's real statuses — the legacy pair
//     delivered + canceled — each carrying its OWN count from its own
//     queue, and the header count pill (700) is the two together, which
//     is exactly what the shipped "There are N orders" line counted;
//   * the cards are the 352 unit carried to a FINISHED order: the
//     progress chip full at 100% and the clock FROZEN at updatedAt
//     ("took 23m"), never ticking on;
//   * selecting a tab swaps the list to that status's queue;
//   * View more · +N (356) pages the ACTIVE tab only.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/components/lists/list_language.dart';
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
import 'package:orders_sdk/src/manager/presentation/board/board_card.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:orders_sdk/src/manager/presentation/history/order_history_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serves the delivered and canceled queues their own rows and their own
/// counts, so the two tabs are genuinely independent — the point of
/// feeding history from the per-status queues rather than the
/// delivered-only history call.
class _FakeSellerOrders implements SellerOrdersRepositoryFacade {
  int deliveredCalls = 0;
  int canceledCalls = 0;

  @override
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    String? rawStatus,
    int? page,
    String? from,
    String? to,
  }) async {
    final bool canceled = status == OrderStatus.canceled;
    if (canceled) {
      canceledCalls++;
    } else {
      deliveredCalls++;
    }
    return ApiResult.success(
      data: OrdersPaginateResponse(
        data: OrderResponseData(
          statistic: OrdersStatistic(
            deliveredOrdersCount: 226,
            cancelOrdersCount: 21,
          ),
          // A full page (the notifier stops paging below ten), so
          // "View more" stays live for the paging assertion.
          orders: [
            for (var i = 1; i <= 10; i++)
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

  late _FakeSellerOrders repository;

  Future<void> pumpHistory(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    repository = _FakeSellerOrders();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deliveredOrdersProvider.overrideWith(
            (ref) => DeliveredOrdersNotifier(repository),
          ),
          canceledOrdersProvider.overrideWith(
            (ref) => CanceledOrdersNotifier(repository),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: OrderHistoryList(compact: true, onOpenDetail: (_, __) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('38a/38d: the legacy delivered+cancelled tabs, each with its '
      'own count; the 700 pill is both together', (tester) async {
    await pumpHistory(tester);

    // Both queues were fetched — one call each, not one shared call.
    expect(repository.deliveredCalls, 1);
    expect(repository.canceledCalls, 1);

    expect(find.byType(ListFilterTabBar), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Canceled'), findsOneWidget);
    expect(find.text('226'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    // 700: the shipped "There are N orders" line, re-homed — 226 + 21.
    expect(find.text('247 orders'), findsOneWidget);
    // 358: the date filter, re-homed from the equalizer FAB to the header.
    expect(find.byType(ListRoundAction), findsOneWidget);
  });

  testWidgets('38a: the card is the 352 unit at 100% with the clock FROZEN',
      (tester) async {
    await pumpHistory(tester);

    final card = tester.widget<BoardOrderCard>(
      find.byType(BoardOrderCard).first,
    );
    expect(card.status, BoardStatus.delivered);
    expect(card.status.progress, 1.0);
    expect(find.text('100%'), findsWidgets);
    // Created 10:00, updated 10:23 — the range freezes, so the card reads
    // how long the order actually took instead of ticking on.
    expect(find.text('23m'), findsWidgets);
  });

  testWidgets('38a: selecting Cancelled swaps the list to that queue',
      (tester) async {
    await pumpHistory(tester);
    expect(find.text('№d-1'), findsOneWidget);

    await tester.tap(find.text('Canceled'));
    await tester.pumpAndSettle();

    expect(find.text('№c-1'), findsOneWidget);
    expect(find.text('№d-1'), findsNothing);
  });

  testWidgets('356: View more pages the ACTIVE tab only', (tester) async {
    await pumpHistory(tester);
    // 226 counted, 10 loaded.
    expect(find.textContaining('216'), findsOneWidget);

    await tester.ensureVisible(find.byType(ListViewMore));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListViewMore));
    await tester.pumpAndSettle();

    expect(repository.deliveredCalls, 2);
    expect(repository.canceledCalls, 1);
  });
}
