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

// The orders workspace picks the approved board (33a, declares ALL) as
// soon as the plane host grants two planes — 600 logical px — not at
// AdaptiveShell's 840 `expanded` class. Tablet store review 2026-09-02,
// still 12-order_queue: the tour's 800 px tablet leg (two planes) was
// falling to the phone list mode.

import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_layout_switch.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_plane_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  Future<void> pumpAt(
    WidgetTester tester,
    double width, {
    void Function(Planes)? onBoardPlanes,
  }) async {
    tester.view.physicalSize = Size(width, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: Size(width, 1280),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: BoardLayoutSwitch(
              compact: (_) => const Text('LIST-MODE'),
              wide: (_) => OrdersBoardPlaneFlow(
                boardBuilder: (context, flow) {
                  onBoardPlanes?.call(Planes.of(context));
                  return const Text('BOARD');
                },
                detailBuilder: (context, order, status, flow) =>
                    Text('DETAIL-${order.id}'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('800 logical (the tour tablet leg, two planes): the BOARD, '
      'hosted on two planes', (tester) async {
    Planes? planes;
    await pumpAt(tester, 800, onBoardPlanes: (p) => planes = p);
    expect(find.text('BOARD'), findsOneWidget);
    expect(find.text('LIST-MODE'), findsNothing);
    expect(planes!.count, 2);
    expect(planes!.span, 2);
  });

  testWidgets('the switch flips exactly where the plane host grants the '
      'second plane', (tester) async {
    await pumpAt(tester, AppBreakpoints.medium - 1);
    expect(find.text('LIST-MODE'), findsOneWidget);
    await pumpAt(tester, AppBreakpoints.medium);
    expect(find.text('BOARD'), findsOneWidget);
    expect(BoardLayoutSwitch.isWide(AppBreakpoints.medium - 1), isFalse);
    expect(BoardLayoutSwitch.isWide(AppBreakpoints.medium), isTrue);
    expect(
      BoardLayoutSwitch.isWide(AppBreakpoints.medium),
      PlaneHost.planeCountFor(AppBreakpoints.medium) >= 2,
    );
  });

  testWidgets('three planes: still the board', (tester) async {
    Planes? planes;
    await pumpAt(tester, 1280, onBoardPlanes: (p) => planes = p);
    expect(find.text('BOARD'), findsOneWidget);
    expect(planes!.count, 3);
  });

  testWidgets('a phone: the list mode', (tester) async {
    await pumpAt(tester, 390);
    expect(find.text('LIST-MODE'), findsOneWidget);
    expect(find.text('BOARD'), findsNothing);
  });

  testWidgets('measured from the constraints the page is given, not the '
      'window: a shell that reserves a side rail keeps the switch and the '
      'plane host in agreement', (tester) async {
    // 800 window, 92 reserved at the start (the manager rail's footprint):
    // 708 for the page — still two planes for both.
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Planes? planes;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(800, 1280),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsetsDirectional.only(start: 92),
              child: BoardLayoutSwitch(
                compact: (_) => const Text('LIST-MODE'),
                wide: (_) => OrdersBoardPlaneFlow(
                  boardBuilder: (context, flow) {
                    planes = Planes.of(context);
                    return const Text('BOARD');
                  },
                  detailBuilder: (context, order, status, flow) =>
                      const Text('DETAIL'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('BOARD'), findsOneWidget);
    expect(planes!.count, 2);
  });
}
