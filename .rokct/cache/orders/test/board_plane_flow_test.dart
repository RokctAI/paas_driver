// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// The approved 33d click behaviour: tapping an order pushes its detail
// with the DEFAULT one-plane claim — the detail takes the LAST plane, the
// board (declaring ALL) yields and compresses, the nav folds to the
// corner back pill, and BACK restores the full-width board.

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_plane_flow.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('33d: detail claims ONE plane in the LAST slot, board yields, '
      'corner back pill folds it back', (tester) async {
    // A three-plane (tablet/desktop) window.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Planes? boardPlanes;
    Planes? detailPlanes;
    OrdersBoardPlaneFlowState? flow;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1280, 800),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: OrdersBoardPlaneFlow(
              boardBuilder: (context, f) {
                flow = f;
                boardPlanes = Planes.of(context);
                return const Text('BOARD');
              },
              detailBuilder: (context, order, status, f) {
                detailPlanes = Planes.of(context);
                return Text('DETAIL-${order.id}');
              },
            ),
          ),
        ),
      ),
    );

    // The board alone: a full workspace, spanning ALL three planes; no
    // back affordance while the flow is at its root.
    expect(find.text('BOARD'), findsOneWidget);
    expect(boardPlanes, isNotNull);
    expect(boardPlanes!.count, 3);
    expect(boardPlanes!.span, 3);
    expect(find.byType(FloatingBackPill), findsNothing);

    // Tap an order: its detail is PUSHED with the default claim.
    flow!.openDetail(OrderData(id: 'ord-1041'), BoardStatus.newOrder);
    await tester.pumpAndSettle();

    // The detail holds exactly ONE plane — the LAST one.
    expect(find.text('DETAIL-ord-1041'), findsOneWidget);
    expect(detailPlanes, isNotNull);
    expect(detailPlanes!.count, 3);
    expect(detailPlanes!.span, 1);
    expect(detailPlanes!.index, 2);
    expect(detailPlanes!.isLast, isTrue);

    // The board YIELDED: same page, compressed onto the two planes that
    // remain — not navigated away.
    expect(find.text('BOARD'), findsOneWidget);
    expect(boardPlanes!.span, 2);
    expect(boardPlanes!.index, 0);
    expect(flow!.openOrderId, 'ord-1041');

    // The nav folds to the back-only corner pill…
    expect(find.byType(FloatingBackPill), findsOneWidget);

    // …and tapping it pops the newest step: detail gone, board restored
    // to all three planes.
    await tester.tap(find.byType(FloatingBackPill));
    await tester.pumpAndSettle();
    expect(find.textContaining('DETAIL-'), findsNothing);
    expect(boardPlanes!.span, 3);
    expect(flow!.openOrderId, isNull);
    expect(find.byType(FloatingBackPill), findsNothing);
  });

  testWidgets('one-plane (phone) window: the pushed detail IS the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    OrdersBoardPlaneFlowState? flow;
    Planes? detailPlanes;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(393, 852),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: OrdersBoardPlaneFlow(
              boardBuilder: (context, f) {
                flow = f;
                return const Text('BOARD');
              },
              detailBuilder: (context, order, status, f) {
                detailPlanes = Planes.of(context);
                return Text('DETAIL-${order.id}');
              },
            ),
          ),
        ),
      ),
    );

    flow!.openDetail(OrderData(id: 'ord-7'), BoardStatus.ready);
    await tester.pumpAndSettle();

    // One plane exists; the newest step holds it — full-screen detail,
    // the board slid off. The mechanism disappears by construction.
    expect(detailPlanes!.count, 1);
    expect(detailPlanes!.span, 1);
    expect(find.text('DETAIL-ord-7'), findsOneWidget);
    expect(find.text('BOARD'), findsNothing);
    expect(find.byType(FloatingBackPill), findsOneWidget);
  });
}
