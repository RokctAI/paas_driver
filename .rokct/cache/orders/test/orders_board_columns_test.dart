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
// THE SEVEN COLUMNS AT TABLET WIDTHS (approved design strip frame 33a, Ray
// 2026-08-29 13:06Z "33a is approved"): "Seven colour-coded columns — New,
// Accepted, Cooking, Ready, On the way, Delivered, Cancelled … Columns keep
// the POS's 235-wide size and scroll SIDEWAYS (Delivered/Cancelled continue
// past the right edge — the bar at the bottom); more space = more detail,
// never seven squeezed columns." The approved render itself shows five
// columns at 1280 logical with the last two past the edge. Tablet stills
// are captured at 1066 logical (the tablet leg) or 800 logical (the retry
// leg), so the rule is pinned at both: every column is in the tree at the
// approved width, none is dropped, and the sideways scroll reaches the
// last one.

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/repositories/demo_seller_orders_repository.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_column.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:orders_sdk/src/manager/presentation/board/orders_board_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    // The queue providers read the board's facade off GetIt; the demo seed
    // is the same stocked shift the guided tour captures.
    GetIt.instance.registerSingleton<SellerOrdersRepositoryFacade>(
      DemoSellerOrdersRepository(),
    );
  });

  tearDownAll(() => GetIt.instance.reset());
  setUp(DemoSellerOrdersRepository.reset);

  for (final size in const [Size(1066, 1600), Size(800, 1280)]) {
    testWidgets('${size.width.toInt()} logical: all seven 33a columns at the '
        'approved 235 width, the far ones reached by the sideways scroll', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: size,
            builder: (_, __) => MaterialApp(
              home: Scaffold(body: OrdersBoardBody(onOpenDetail: (_, __) {})),
            ),
          ),
        ),
      );
      // The live clocks tick every second, so settle by hand.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final columns = find.byType(BoardOrderColumn);
      // Every status column is on the board, in the approved order — none
      // dropped, none grouped away.
      expect(
        tester.widgetList<BoardOrderColumn>(columns).map((c) => c.status),
        BoardRules.columnsFor(),
      );
      expect(BoardRules.columnsFor(), hasLength(7));
      for (final column in tester.widgetList(columns)) {
        // The column's own box (its Container adds the 12 end margin).
        final box = find
            .descendant(
              of: find.byWidget(column),
              matching: find.byType(DecoratedBox),
            )
            .first;
        expect(tester.getSize(box).width, BoardOrderColumn.width);
      }

      // Seven 235-wide columns exceed either width, so the last one starts
      // past the right edge — the approved sideways scroll carries it.
      expect(tester.getTopLeft(columns.last).dx, greaterThan(size.width));
      expect(find.byType(Scrollbar), findsOneWidget);

      await tester.drag(find.byType(Scrollbar), const Offset(-2000, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final last = tester.getRect(columns.last);
      expect(last.right, lessThanOrEqualTo(size.width));
      expect(last.left, greaterThanOrEqualTo(0));

      // Unmount so the clocks stop before the test ends.
      await tester.pumpWidget(const SizedBox());
    });
  }
}
