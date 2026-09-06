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
// THE WALK-IN ORDER FLOW ON PLANES at the three widths the plane model
// names (approved 37a–37e, Ray 2026-08-30 12:23Z):
//
//   * 1280 (three planes): the board yields to a one-plane rail beside
//     the walk-in's products | cart (37a); a product tap pushes its
//     details pane into the LAST plane (the 12:02Z sheet fork); Next
//     pushes shipping into the LAST plane and the board pops off stage
//     (37b); the map claims ALL and refuses neighbours (37c); the corner
//     pill pops the NEWEST step only; at the root it exits the route;
//   * 800 (two planes, the fold): the walk-in's two-plane claim takes the
//     screen, no rail; shipping on stage compresses the walk-in to its
//     products column — the cart one Back away;
//   * 393 (one plane): the newest step is the whole screen — the host
//     never builds this flow there, but the mechanism collapses by
//     construction.

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/walk_in/walk_in_plane_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  WalkInPlaneFlowState? flow;
  var exited = false;

  Widget subject() => WalkInPlaneFlow(
    backIcon: Icons.arrow_back,
    onExit: () => exited = true,
    boardRailBuilder: (_) => const Text('RAIL'),
    productsBuilder: (context, f) {
      flow = f;
      return const Text('PRODUCTS');
    },
    cartBuilder: (_, __) => const Text('CART'),
    foodDetailsBuilder: (_, product, __) => Text('DETAIL-${product.id}'),
    shippingBuilder: (_, __) => const Text('SHIPPING'),
    addressBuilder: (_, __) => const Text('MAP'),
    deliveryTimeBuilder: (_, __) => const Text('TIME'),
  );

  Planes planesOf(WidgetTester tester, String marker) =>
      Planes.of(tester.element(find.text(marker)));

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    flow = null;
    exited = false;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: size,
        builder: (_, __) => MaterialApp(home: Scaffold(body: subject())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    '1280 (three planes): 37a rail | products | cart, the sheet fork, 37b '
    'shipping in the LAST plane with the board off stage, 37c the map '
    'ALL and alone, the pill popping the newest step each time',
    (tester) async {
      await pumpAt(tester, const Size(1280, 800));

      // 37a: the board yields onto plane 1 (675); the walk-in claims TWO
      // and spreads products | cart over planes 2–3.
      expect(find.text('RAIL'), findsOneWidget);
      expect(find.text('PRODUCTS'), findsOneWidget);
      expect(find.text('CART'), findsOneWidget);
      final rail = planesOf(tester, 'RAIL');
      expect(rail.count, 3);
      expect(rail.index, 0);
      expect(rail.span, 1);
      final walkIn = planesOf(tester, 'PRODUCTS');
      expect(walkIn.index, 1);
      expect(walkIn.span, 2);
      expect(walkIn.isLast, isTrue);
      // A pushed page holds planes: the corner pill (347) is on screen.
      expect(find.byType(FloatingBackPill), findsOneWidget);

      // The sheet fork: a product tap pushes its details into the LAST
      // plane; the walk-in keeps spreading, the board pops off stage.
      flow!.openFoodDetails(ProductData(id: 'p-burger'));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL-p-burger'), findsOneWidget);
      final detail = planesOf(tester, 'DETAIL-p-burger');
      expect(detail.index, 2);
      expect(detail.span, 1);
      expect(planesOf(tester, 'PRODUCTS').span, 2);
      expect(find.text('CART'), findsOneWidget);
      expect(find.text('RAIL'), findsNothing);

      // Back pops the pane only; the rail returns.
      await tester.tap(find.byType(FloatingBackPill));
      await tester.pumpAndSettle();
      expect(find.textContaining('DETAIL-'), findsNothing);
      expect(find.text('RAIL'), findsOneWidget);
      expect(exited, isFalse);

      // 37b: Next pushes /shipping-address — default claim, LAST plane;
      // the walk-in keeps products | cart on planes 1–2; the board is off
      // stage.
      flow!.openShipping();
      await tester.pumpAndSettle();
      expect(find.text('SHIPPING'), findsOneWidget);
      final shipping = planesOf(tester, 'SHIPPING');
      expect(shipping.index, 2);
      expect(shipping.span, 1);
      expect(shipping.isLast, isTrue);
      final yielded = planesOf(tester, 'PRODUCTS');
      expect(yielded.index, 0);
      expect(yielded.span, 2);
      expect(find.text('CART'), findsOneWidget);
      expect(find.text('RAIL'), findsNothing);

      // 37c: the map declares ALL and refuses neighbours — full bleed.
      flow!.openAddress();
      await tester.pumpAndSettle();
      expect(find.text('MAP'), findsOneWidget);
      final map = planesOf(tester, 'MAP');
      expect(map.index, 0);
      expect(map.span, 3);
      expect(map.count, 3);
      expect(find.text('SHIPPING'), findsNothing);
      expect(find.text('PRODUCTS'), findsNothing);

      // Back abandons the pick; shipping is back in the last plane.
      await tester.tap(find.byType(FloatingBackPill));
      await tester.pumpAndSettle();
      expect(find.text('MAP'), findsNothing);
      expect(planesOf(tester, 'SHIPPING').index, 2);
      expect(flow!.addressOpen, isFalse);

      // The finish step takes the last plane; the cascade compresses the
      // walk-in to its products column beside shipping.
      flow!.openDeliveryTime();
      await tester.pumpAndSettle();
      expect(planesOf(tester, 'TIME').index, 2);
      expect(planesOf(tester, 'SHIPPING').index, 1);
      final compressed = planesOf(tester, 'PRODUCTS');
      expect(compressed.index, 0);
      expect(compressed.span, 1);
      expect(find.text('CART'), findsNothing);

      // Back unwinds one step at a time, and at the root exits the route
      // (the board re-expands beneath it).
      await tester.tap(find.byType(FloatingBackPill));
      await tester.pumpAndSettle();
      expect(find.text('TIME'), findsNothing);
      expect(flow!.step, WalkInStep.shipping);
      await tester.tap(find.byType(FloatingBackPill));
      await tester.pumpAndSettle();
      expect(find.text('SHIPPING'), findsNothing);
      expect(find.text('RAIL'), findsOneWidget);
      expect(planesOf(tester, 'PRODUCTS').span, 2);
      expect(exited, isFalse);
      await tester.tap(find.byType(FloatingBackPill));
      await tester.pumpAndSettle();
      expect(exited, isTrue);
    },
  );

  testWidgets(
    '800 (two planes, the fold): the walk-in\'s TWO takes the screen — no '
    'rail; shipping on stage compresses it to the products column',
    (tester) async {
      await pumpAt(tester, const Size(800, 1280));

      final walkIn = planesOf(tester, 'PRODUCTS');
      expect(walkIn.count, 2);
      expect(walkIn.index, 0);
      expect(walkIn.span, 2);
      expect(find.text('CART'), findsOneWidget);
      expect(find.text('RAIL'), findsNothing);
      expect(find.byType(FloatingBackPill), findsOneWidget);

      flow!.openShipping();
      await tester.pumpAndSettle();
      final shipping = planesOf(tester, 'SHIPPING');
      expect(shipping.index, 1);
      expect(shipping.span, 1);
      final yielded = planesOf(tester, 'PRODUCTS');
      expect(yielded.index, 0);
      expect(yielded.span, 1);
      // Yielded to one plane: the products column alone, the cart one
      // Back away.
      expect(find.text('CART'), findsNothing);

      // The map still takes everything.
      flow!.openAddress();
      await tester.pumpAndSettle();
      expect(planesOf(tester, 'MAP').span, 2);
      expect(find.text('SHIPPING'), findsNothing);

      await tester.tap(find.byType(FloatingBackPill));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingBackPill));
      await tester.pumpAndSettle();
      expect(find.text('SHIPPING'), findsNothing);
      expect(find.text('CART'), findsOneWidget);
    },
  );

  testWidgets(
    '393 (one plane): the newest step IS the screen — the plane model '
    'collapses to the push chain by construction',
    (tester) async {
      await pumpAt(tester, const Size(393, 852));

      final walkIn = planesOf(tester, 'PRODUCTS');
      expect(walkIn.count, 1);
      expect(walkIn.span, 1);
      expect(find.text('CART'), findsNothing);
      expect(find.text('RAIL'), findsNothing);

      flow!.openShipping();
      await tester.pumpAndSettle();
      expect(find.text('SHIPPING'), findsOneWidget);
      expect(find.text('PRODUCTS'), findsNothing);
      expect(find.byType(FloatingBackPill), findsOneWidget);
    },
  );
}
