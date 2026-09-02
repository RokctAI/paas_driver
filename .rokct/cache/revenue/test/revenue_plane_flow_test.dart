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
// The approved revenue plane behaviour (36a: the dashboard declares ALL;
// 36c: the drill-down takes the LAST plane, the origin compresses onto
// TWO, and — unlike the catalog's permanent read pane — the pushed detail
// FOLDS the nav to the corner pill per 12:36Z; 36b: the phone hosts the
// dashboard alone).

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:revenue_sdk/src/common/infrastructure/models/response/profit_report_response.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/revenue_plane_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  const product = ProductProfit(id: 'prd-42', name: 'Bunny Chow');

  Widget host({
    required Size size,
    ProductProfit? selected,
    required void Function() onPop,
    void Function(Planes)? onDashboardPlanes,
    void Function(Planes)? onDetailPlanes,
  }) => ScreenUtilInit(
    designSize: size,
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: RevenuePlaneFlow(
          selectedProduct: selected,
          dashboardBuilder: (context) {
            onDashboardPlanes?.call(Planes.of(context));
            return const Text('DASHBOARD');
          },
          detailBuilder: (context, product) {
            onDetailPlanes?.call(Planes.of(context));
            return Text('DETAIL-${product.id}');
          },
          onCloseDetail: onPop,
        ),
      ),
    ),
  );

  testWidgets('36a: at three planes the dashboard alone claims ALL — no pill',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Planes? dashboardPlanes;
    await tester.pumpWidget(
      host(
        size: const Size(1280, 800),
        selected: null,
        onPop: () {},
        onDashboardPlanes: (p) => dashboardPlanes = p,
      ),
    );
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(dashboardPlanes!.count, 3);
    expect(dashboardPlanes!.span, 3);
    expect(find.byType(FloatingBackPill), findsNothing);
  });

  testWidgets(
      '36c: the drill-down takes the LAST plane, the origin compresses '
      'onto TWO, and the nav folds to the corner pill (a pushed page '
      'holds a plane — 12:36Z); the pill pops it', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    bool popped = false;
    Planes? dashboardPlanes;
    Planes? detailPlanes;
    await tester.pumpWidget(
      host(
        size: const Size(1280, 800),
        selected: product,
        onPop: () => popped = true,
        onDashboardPlanes: (p) => dashboardPlanes = p,
        onDetailPlanes: (p) => detailPlanes = p,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('DETAIL-prd-42'), findsOneWidget);
    expect(dashboardPlanes!.count, 3);
    expect(dashboardPlanes!.span, 2);
    expect(dashboardPlanes!.index, 0);
    expect(detailPlanes!.span, 1);
    expect(detailPlanes!.index, 2);
    expect(detailPlanes!.isLast, isTrue);
    expect(find.byType(FloatingBackPill), findsOneWidget);

    await tester.tap(find.byType(FloatingBackPill));
    expect(popped, isTrue);
  });

  testWidgets('two-plane width: dashboard | detail, one plane each, folded',
      (tester) async {
    tester.view.physicalSize = const Size(700, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Planes? dashboardPlanes;
    Planes? detailPlanes;
    await tester.pumpWidget(
      host(
        size: const Size(700, 800),
        selected: product,
        onPop: () {},
        onDashboardPlanes: (p) => dashboardPlanes = p,
        onDetailPlanes: (p) => detailPlanes = p,
      ),
    );
    await tester.pumpAndSettle();
    expect(dashboardPlanes!.count, 2);
    expect(dashboardPlanes!.span, 1);
    expect(detailPlanes!.span, 1);
    expect(detailPlanes!.isLast, isTrue);
    expect(find.byType(FloatingBackPill), findsOneWidget);
  });

  testWidgets(
      '36b: phone — the flow hosts the dashboard alone (selection pushes a '
      'REAL route outside the flow, which carries its own corner pill)',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Planes? dashboardPlanes;
    await tester.pumpWidget(
      host(
        size: const Size(393, 852),
        selected: null,
        onPop: () {},
        onDashboardPlanes: (p) => dashboardPlanes = p,
      ),
    );
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(dashboardPlanes!.count, 1);
    expect(dashboardPlanes!.span, 1);
    expect(find.byType(FloatingBackPill), findsNothing);
  });
}
