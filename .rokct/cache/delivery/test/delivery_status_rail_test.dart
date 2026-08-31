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

// FRAME 49c of design strip section 49 — the job rail.
//
// The three things a later edit could quietly undo:
//
//   * the rail is DERIVED and invents nothing — the second node has no
//     server status behind it and is earned at the completeCheckout
//     confirmation, which is `isGoUser` flipping;
//   * the server status wins wherever it has an opinion, so a rail
//     rebuilt from a fetched `on_a_way`/`delivered` order reads right
//     even before the local flags catch up;
//   * it is a read-out: four nodes, always all four, and no tap target
//     anywhere on it.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:delivery_sdk/src/driver/presentation/widgets/delivery_status_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 900),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );

Future<void> _pump(WidgetTester tester, DeliveryStage stage) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(DeliveryStatusRail(current: stage)));
  await tester.pumpAndSettle();
}

Container _node(WidgetTester tester, DeliveryStage stage) => tester
    .widget<Container>(find.byKey(Key('deliveryStatusNode_${stage.name}')));

Color? _fill(WidgetTester tester, DeliveryStage stage) =>
    (_node(tester, stage).decoration! as BoxDecoration).color;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppStyle.isDark = true);

  group('the derivation — what the rail is allowed to know', () {
    test('a fresh accepted job sits on the first node', () {
      expect(
        DeliveryStatusRail.stageFor(
          status: 'accepted',
          isGoRestaurant: false,
          isGoUser: false,
        ),
        DeliveryStage.accepted,
      );
    });

    test('heading to the shop is the At shop node', () {
      expect(
        DeliveryStatusRail.stageFor(
          status: 'accepted',
          isGoRestaurant: true,
          isGoUser: false,
        ),
        DeliveryStage.atShop,
      );
    });

    test(
        'the completeCheckout confirmation — and NOT a server status — is '
        'what advances the second node', () {
      // The order is still 'accepted' on the wire: there is no "at shop"
      // status anywhere in the Order doctype and the rail does not
      // pretend otherwise. What moved is the local flag the same
      // confirmation already flips.
      expect(
        DeliveryStatusRail.stageFor(
          status: 'accepted',
          isGoRestaurant: false,
          isGoUser: true,
        ),
        DeliveryStage.onTheWay,
      );
    });

    test('a fetched on_a_way order reads on the way with no local flag', () {
      expect(
        DeliveryStatusRail.stageFor(
          status: 'on_a_way',
          isGoRestaurant: false,
          isGoUser: false,
        ),
        DeliveryStage.onTheWay,
      );
    });

    test('delivered wins over every live flag', () {
      expect(
        DeliveryStatusRail.stageFor(
          status: 'delivered',
          isGoRestaurant: true,
          isGoUser: true,
        ),
        DeliveryStage.delivered,
      );
    });

    test('an unknown or absent status falls back to accepted', () {
      expect(
        DeliveryStatusRail.stageFor(
          status: null,
          isGoRestaurant: false,
          isGoUser: false,
        ),
        DeliveryStage.accepted,
      );
    });
  });

  group('the drawing', () {
    testWidgets('all four nodes are always on the rail', (tester) async {
      await _pump(tester, DeliveryStage.atShop);
      expect(find.byKey(const Key('deliveryStatusRail')), findsOneWidget);
      for (final stage in DeliveryStage.values) {
        expect(
          find.byKey(Key('deliveryStatusNode_${stage.name}')),
          findsOneWidget,
          reason: '${stage.name} must be drawn at every stage',
        );
      }
    });

    testWidgets('nodes before the current one are filled, the rest are not',
        (tester) async {
      await _pump(tester, DeliveryStage.onTheWay);
      expect(_fill(tester, DeliveryStage.accepted), AppStyle.primary);
      expect(_fill(tester, DeliveryStage.atShop), AppStyle.primary);
      expect(_fill(tester, DeliveryStage.onTheWay), AppStyle.transparent);
      expect(_fill(tester, DeliveryStage.delivered), AppStyle.transparent);
    });

    testWidgets('a done node is ticked; the current one is not',
        (tester) async {
      await _pump(tester, DeliveryStage.onTheWay);
      expect(_node(tester, DeliveryStage.accepted).child, isA<Icon>());
      expect(_node(tester, DeliveryStage.onTheWay).child, isNull);
    });

    testWidgets('the current node carries the heavier ring', (tester) async {
      await _pump(tester, DeliveryStage.atShop);
      double width(DeliveryStage s) =>
          ((_node(tester, s).decoration! as BoxDecoration).border! as Border)
              .top
              .width;
      expect(width(DeliveryStage.atShop),
          greaterThan(width(DeliveryStage.delivered)));
    });

    testWidgets('nothing on the rail is tappable', (tester) async {
      await _pump(tester, DeliveryStage.atShop);
      expect(
        find.descendant(
          of: find.byKey(const Key('deliveryStatusRail')),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('deliveryStatusRail')),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });
  });
}
