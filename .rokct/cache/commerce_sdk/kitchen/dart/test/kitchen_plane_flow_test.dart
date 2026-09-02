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
// The approved kitchen plane behaviour (34a: kitchen declares ALL — at
// three planes queue spreads over 1–2 + detail in the LAST plane, no
// corner pill because the detail is a permanent pane; at two planes
// queue | detail; phone: queue full-screen, selection pushes the detail
// with the corner back pill, back pops it — 34b/34c, the 12:36Z fold).

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_plane_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  const order = KitchenOrderData(id: 'ord-1043');

  Widget host({
    required Size size,
    KitchenOrderData? selected,
    required void Function() onClose,
    void Function(Planes)? onQueuePlanes,
    void Function(Planes)? onDetailPlanes,
  }) => ScreenUtilInit(
    designSize: size,
    builder: (_, __) => MaterialApp(
      home: Scaffold(
        body: KitchenPlaneFlow(
          selectedOrder: selected,
          queueBuilder: (context) {
            onQueuePlanes?.call(Planes.of(context));
            return const Text('QUEUE');
          },
          detailBuilder: (context, order) {
            onDetailPlanes?.call(Planes.of(context));
            return Text('DETAIL-${order.id}');
          },
          onCloseDetail: onClose,
        ),
      ),
    ),
  );

  testWidgets('34a: at three planes the queue alone still claims ALL',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Planes? queuePlanes;
    await tester.pumpWidget(
      host(
        size: const Size(1280, 800),
        selected: null,
        onClose: () {},
        onQueuePlanes: (p) => queuePlanes = p,
      ),
    );
    expect(find.text('QUEUE'), findsOneWidget);
    expect(queuePlanes!.count, 3);
    expect(queuePlanes!.span, 3);
    expect(find.byType(FloatingBackPill), findsNothing);
  });

  testWidgets(
      '34a: a selected order takes the LAST plane, the queue compresses '
      'onto TWO — and no corner pill (the detail is a permanent pane, the '
      'full shell nav stays)', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Planes? queuePlanes;
    Planes? detailPlanes;
    await tester.pumpWidget(
      host(
        size: const Size(1280, 800),
        selected: order,
        onClose: () {},
        onQueuePlanes: (p) => queuePlanes = p,
        onDetailPlanes: (p) => detailPlanes = p,
      ),
    );
    expect(find.text('QUEUE'), findsOneWidget);
    expect(find.text('DETAIL-ord-1043'), findsOneWidget);
    expect(queuePlanes!.count, 3);
    expect(queuePlanes!.span, 2);
    expect(queuePlanes!.index, 0);
    expect(detailPlanes!.span, 1);
    expect(detailPlanes!.index, 2);
    expect(detailPlanes!.isLast, isTrue);
    expect(find.byType(FloatingBackPill), findsNothing);
  });

  testWidgets('two-plane width: queue | detail, one plane each',
      (tester) async {
    tester.view.physicalSize = const Size(700, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Planes? queuePlanes;
    Planes? detailPlanes;
    await tester.pumpWidget(
      host(
        size: const Size(700, 800),
        selected: order,
        onClose: () {},
        onQueuePlanes: (p) => queuePlanes = p,
        onDetailPlanes: (p) => detailPlanes = p,
      ),
    );
    expect(queuePlanes!.count, 2);
    expect(queuePlanes!.span, 1);
    expect(detailPlanes!.span, 1);
    expect(detailPlanes!.isLast, isTrue);
    expect(find.byType(FloatingBackPill), findsNothing);
  });

  testWidgets(
      '34b/34c: phone — queue full-screen; a selection replaces it with '
      'the pushed detail and the corner back pill, back pops', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    bool closed = false;
    await tester.pumpWidget(
      host(size: const Size(393, 852), selected: null, onClose: () {}),
    );
    expect(find.text('QUEUE'), findsOneWidget);
    expect(find.byType(FloatingBackPill), findsNothing);

    await tester.pumpWidget(
      host(
        size: const Size(393, 852),
        selected: order,
        onClose: () => closed = true,
      ),
    );
    await tester.pumpAndSettle();
    // One plane: the detail covers the queue; the nav folds to the pill.
    expect(find.text('DETAIL-ord-1043'), findsOneWidget);
    expect(find.text('QUEUE'), findsNothing);
    expect(find.byType(FloatingBackPill), findsOneWidget);

    await tester.tap(find.byType(FloatingBackPill));
    expect(closed, isTrue);
  });
}
