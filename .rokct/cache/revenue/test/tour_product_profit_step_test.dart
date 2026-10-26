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
//
// The manager tour's `revenue_product_profit` step must open the profit
// detail on a phone. On the phone the dashboard is ONE lazy vertical
// ListView and the product rows sit below the fold, so they are not built
// until the list scrolls. The step used `scrollUntilVisible(row.first)`,
// which throws "No element" while no row exists yet; its catch swallowed
// that, nothing scrolled, and the tour photographed the dashboard twice
// (paas_manager tour 2026-10-26, revenue_income == revenue_product_profit).
//
// 1.14.6 dragged the list with gestures; that passed here and still
// repeated the dashboard on the device (run 40311495619), so 1.14.7 drops
// gestures: jumpTo on the list holding the trend chart, ensureVisible,
// then the row's own onTap.
//
// This runs the same logic as the step in
// templates/tour/revenue_manager.tour.yaml against a phone-width dashboard
// and checks the detail route was pushed. Keep the two in step.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/seller_statistics.dart';
import 'package:revenue_sdk/src/manager/infrastructure/repositories/seller_statistics_repository.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/profit_product_list.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/revenue_detail_page.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/revenue_workspace.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/trend_chart.dart';

import 'support/demo_fixtures_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await startRevenueDemoSession();
    if (!GetIt.instance.isRegistered<SellerStatisticsRepositoryFacade>()) {
      GetIt.instance.registerLazySingleton<SellerStatisticsRepositoryFacade>(
        SellerStatisticsRepository.new,
      );
    }
  });

  testWidgets('the tour step opens the product profit detail on a phone', (
    tester,
  ) async {
    // A typical phone in logical pixels.
    const size = Size(412, 870);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // flutter_test's square font overflows rows horizontally; that says
    // nothing about the device (see revenue_workspace_layout_test.dart).
    final priorOnError = FlutterError.onError;
    FlutterError.onError = (_) {};
    addTearDown(() => FlutterError.onError = priorOnError);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: size,
        builder: (_, __) => const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: RevenueWorkspace(shopName: 'Demo Store')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Finder row = find.byType(ProductProfitRow);
    final Finder list = find.ancestor(
      of: find.byType(RevenueTrendChart),
      matching: find.byWidgetPredicate(
        (Widget w) => w is Scrollable && w.axis == Axis.vertical,
      ),
    );
    // The bug's precondition: the rows start below the fold, unbuilt.
    expect(row, findsNothing);
    expect(list, findsWidgets);

    final ScrollPosition position = tester
        .state<ScrollableState>(list.first)
        .position;
    int jumps = 0;
    while (row.evaluate().isEmpty &&
        position.pixels < position.maxScrollExtent &&
        jumps < 40) {
      position.jumpTo(
        (position.pixels + 300).clamp(0.0, position.maxScrollExtent),
      );
      jumps++;
      await tester.pump();
    }
    expect(row, findsWidgets);
    await Scrollable.ensureVisible(tester.element(row.first));
    await tester.pump();
    tester.widget<ProductProfitRow>(row.first).onTap?.call();
    await tester.pumpAndSettle();

    expect(find.byType(RevenueDetailPage), findsOneWidget);
  });
}
