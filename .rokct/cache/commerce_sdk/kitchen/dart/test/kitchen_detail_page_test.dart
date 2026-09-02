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
// The phone's pushed detail route (approved 34c): a REAL route that
// covers the shell — only the corner back pill remains (the 12:36Z nav
// fold) — and pops itself when the selection dies underneath.

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sdk/src/manager/application/kitchen/kitchen_notifier.dart';
import 'package:kitchen_sdk/src/manager/application/kitchen/kitchen_provider.dart';
import 'package:kitchen_sdk/src/manager/domain/interface/kitchen_orders.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/response/kitchen_orders_response.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_detail_page.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubRepo implements KitchenOrdersRepositoryFacade {
  KitchenOrdersResponse response = const KitchenOrdersResponse();

  @override
  Future<ApiResult<KitchenOrdersResponse>> getKitchenOrders({
    KitchenStatus? status,
    String? search,
    int? page,
  }) async => ApiResult.success(data: response);

  @override
  Future<ApiResult<void>> updateOrderStatus({
    required String orderId,
    required String wireStatus,
  }) async => const ApiResult.success(data: null);

  @override
  Future<ApiResult<void>> updateDishStatus({
    required String orderId,
    required String dishId,
    required DishStatus status,
  }) async => const ApiResult.success(data: null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets(
      '34c: the pushed detail covers the shell, shows the corner pill; '
      'back pops to the queue', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _StubRepo()
      ..response = KitchenOrdersResponse(
        orders: [
          KitchenOrderData(
            id: 'ord-1043',
            status: KitchenStatus.cooking,
            deliveryType: 'delivery',
            createdAt: DateTime(2026, 8, 29, 11, 58),
            updatedAt: DateTime(2026, 8, 29, 12, 30),
            dishes: const [
              KitchenDishData(
                id: 'd1',
                title: 'Beef Kota',
                quantity: 2,
                prepStatus: DishStatus.done,
              ),
            ],
          ),
        ],
      );
    final notifier = KitchenNotifier(repo, playChime: () {});
    await notifier.fetchOrders(isRefresh: true);
    notifier.selectOrder('ord-1043');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [kitchenProvider.overrideWith((ref) => notifier)],
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (_, __) => MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: const Text('SHELL-QUEUE'),
                floatingActionButton: const Text('SHELL-NAV'),
                persistentFooterButtons: [
                  TextButton(
                    onPressed: () => KitchenDetailPage.push(context),
                    child: const Text('OPEN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    // The route covers the shell — nav gone, dish pane + corner pill in.
    expect(find.text('SHELL-NAV'), findsNothing);
    expect(find.textContaining('Beef Kota'), findsOneWidget);
    expect(find.byType(FloatingBackPill), findsOneWidget);

    await tester.tap(find.byType(FloatingBackPill));
    await tester.pumpAndSettle();
    expect(find.text('SHELL-NAV'), findsOneWidget);
    expect(find.byType(FloatingBackPill), findsNothing);
  });

  testWidgets('the detail pops itself when the selection dies underneath',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _StubRepo()
      ..response = KitchenOrdersResponse(
        orders: [
          KitchenOrderData(
            id: 'ord-1',
            status: KitchenStatus.ready,
            createdAt: DateTime(2026, 8, 29, 11, 58),
            updatedAt: DateTime(2026, 8, 29, 12, 30),
          ),
        ],
      );
    final notifier = KitchenNotifier(repo, playChime: () {});
    await notifier.fetchOrders(isRefresh: true);
    notifier.selectOrder('ord-1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [kitchenProvider.overrideWith((ref) => notifier)],
        child: ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (_, __) => MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => KitchenDetailPage.push(context),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.byType(KitchenDetailPage), findsOneWidget);

    // The order leaves the queue (handed over, refresh emptied it).
    repo.response = const KitchenOrdersResponse();
    await notifier.fetchOrders(isRefresh: true);
    await tester.pumpAndSettle();

    expect(find.byType(KitchenDetailPage), findsNothing);
    expect(find.text('OPEN'), findsOneWidget);
  });
}
