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
// The revenue dashboard's scrolling columns must actually LAY OUT.
//
// The paired KPI tiles (`_kpiTiles(paired: true)`) sit side by side in a
// `Row(crossAxisAlignment: CrossAxisAlignment.stretch)`, and every caller
// drops that row straight into a `ListView`. A stretch row passes its own
// incoming maxHeight down as a TIGHT height, and a ListView's incoming
// maxHeight is infinite — so each tile was asked to be infinitely tall and
// layout threw "BoxConstraints forces an infinite height" at
// revenue_workspace.dart:530. Flutter catches that at the row's own
// layout(), which then has no size; the failure walks up through
// SliverList to the viewport, and because a viewport is sizedByParent it
// keeps its own size while its sliver has no geometry — so the column
// renders NOTHING while everything beside it renders fine.
//
// That is exactly what the guided tour photographed on 2026-09-02
// (paas_manager run 33623501812, commit 3543a6b6): on the phone the
// ListView IS the screen, so 16-revenue_income came back one flat empty
// fill; on the tablet only the LEFT column is that ListView, so the
// profit-by-product list on the right survived while the
// revenue-vs-profit chart's column went blank. The framework then
// asserted '!semantics.parentDataDirty' on every later frame, which is
// what made the tour's `flutter test` exit 1.
//
// Two things this file deliberately does NOT do:
//
//  * It does not assert on the widget tree alone. A ListView builds its
//    children lazily during layout, so when layout is abandoned the
//    children after the failure are never built at all — `findsNothing`
//    is the bug's signature, and a "the chart exists" check that passed
//    on a blank screen would be worthless. It asserts REAL GEOMETRY.
//
//  * It does not assert `takeException() == null`. flutter_test renders
//    with a square test font (every glyph one em wide: "Revenue" at 24px
//    measures exactly 168px here), so horizontal RenderFlex overflow is
//    unavoidable in a widget test and says nothing about the device. The
//    checks below name the two errors that DO mean a column collapsed.

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:revenue_sdk/src/common/domain/interface/seller_statistics.dart';
import 'package:revenue_sdk/src/manager/infrastructure/repositories/demo_seller_statistics_repository.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/kpi_tiles.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/revenue_workspace.dart';
import 'package:revenue_sdk/src/manager/presentation/revenue/trend_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    // profitDashboardProvider resolves the facade out of GetIt, exactly as
    // ManagerRevenueDependencies.register() wires it in a composed app.
    if (!GetIt.instance.isRegistered<SellerStatisticsRepositoryFacade>()) {
      GetIt.instance.registerLazySingleton<SellerStatisticsRepositoryFacade>(
        DemoSellerStatisticsRepository.new,
      );
    }
  });

  /// The two rendering errors that mean a subtree's layout was abandoned.
  /// Anything else (notably overflow, see the header note) is ignored.
  const collapseSignatures = [
    'forces an infinite height',
    'was not laid out',
  ];

  /// Pumps the workspace at [size] and returns the rendering errors that
  /// mean a column collapsed.
  Future<List<String>> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final errors = <FlutterErrorDetails>[];
    final priorOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
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
    } finally {
      FlutterError.onError = priorOnError;
    }

    return [
      for (final error in errors)
        if (collapseSignatures
            .any((s) => error.exception.toString().contains(s)))
          error.exception.toString(),
    ];
  }

  /// Every render box behind [finder], or null for one layout never gave a
  /// size to — the bug's fingerprint.
  List<Size?> sizesOf(Finder finder) => [
        for (final element in finder.evaluate())
          if (element.renderObject case final RenderBox box when box.hasSize)
            box.size
          else
            null,
      ];

  void expectRealTiles(Finder finder, {required int atLeast}) {
    final sizes = sizesOf(finder);
    expect(sizes.length, greaterThanOrEqualTo(atLeast),
        reason: 'the KPI tiles were never even built — the column collapsed '
            'before the ListView could lay them out');
    for (final size in sizes) {
      expect(size, isNotNull, reason: 'a paired KPI tile was never laid out');
      expect(size!.height.isFinite, isTrue,
          reason: 'a paired KPI tile was stretched to an infinite height');
      expect(size.height, greaterThan(0));
    }
  }

  testWidgets(
      '36b phone: the single scrolling column lays out — the trend chart '
      'gets real height instead of a blank screen', (tester) async {
    final collapses = await pumpAt(tester, const Size(393, 852));
    expect(collapses, isEmpty);

    expect(find.byType(RevenueTrendChart), findsOneWidget,
        reason: 'the chart was never built — the phone column collapsed');
    final chart = sizesOf(find.byType(RevenueTrendChart)).single;
    expect(chart, isNotNull, reason: 'the chart was never laid out');
    expect(chart!.height, greaterThan(0));
    expect(chart.width, greaterThan(0));

    // The paired tiles above it are what broke the column, so pin them too.
    expectRealTiles(find.byType(RevenueKpiTile), atLeast: 5);
  });

  testWidgets(
      '36a two planes: the KPI + chart column lays out beside the products '
      'column instead of going blank', (tester) async {
    final collapses = await pumpAt(tester, const Size(900, 800));
    expect(collapses, isEmpty);

    expect(find.byType(RevenueTrendChart), findsOneWidget,
        reason: 'the chart was never built — the left column collapsed');
    final chart = sizesOf(find.byType(RevenueTrendChart)).single;
    expect(chart, isNotNull, reason: 'the chart was never laid out');
    expect(chart!.height, greaterThan(0));
    expect(chart.width, greaterThan(0));

    expectRealTiles(find.byType(RevenueKpiTile), atLeast: 5);
  });

  testWidgets('36a three planes: the KPI column lays out on its own plane',
      (tester) async {
    final collapses = await pumpAt(tester, const Size(1280, 800));
    expect(collapses, isEmpty);

    expectRealTiles(find.byType(RevenueKpiTile), atLeast: 5);
  });

  testWidgets(
      'the paired tiles are the SAME height — stretch still means "match '
      'your sibling", it just has a finite height to match against',
      (tester) async {
    final collapses = await pumpAt(tester, const Size(393, 852));
    expect(collapses, isEmpty);

    // profit|margin and orders|avg: five tiles, the first full-width, then
    // two pairs whose members must agree on height.
    final sizes = sizesOf(find.byType(RevenueKpiTile));
    expect(sizes.length, 5);
    expect(sizes[1]!.height, sizes[2]!.height);
    expect(sizes[3]!.height, sizes[4]!.height);
  });
}
