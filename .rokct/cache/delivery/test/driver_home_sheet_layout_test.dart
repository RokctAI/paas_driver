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

// The driver home sheet's LAYOUT CONTRACT, pinned after the guided tour
// died on it.
//
// `BottomSheetScreen` returns an `AnimatedPositioned`, so the widget is
// only ever legal as a direct child of the home page's `Stack`, and the
// Stack gives a child positioned on ONE axis no horizontal bound at all.
// While the sheet was a single self-sizing `Container` that was
// survivable; the moment the weather banner turned it into a
// `Column(crossAxisAlignment: stretch)` the column started handing its
// children `w=Infinity` and the driver home stopped laying out at all:
//
//   BoxConstraints forces an infinite width.
//     BoxConstraints(w=Infinity, 0.0<=h<=Infinity)
//   The relevant error-causing widget was: Column
//     .../lib/presentation/pages/home/bottom_sheet_screen.dart
//
// So the sheet must pin BOTH horizontal edges. These tests pump the real
// template in the frame it actually renders in — a Stack under a
// Scaffold body — and fail on any exception, which is precisely what the
// tour reported. Deleting `left: 0, right: 0`, or reintroducing a
// stretching column that is not width-bounded, turns them red.
//
// The template is imported by relative path because `templates/` is what
// the composer installs into the host's generated `lib/`; this particular
// file carries no composer placeholders, so it is the same source the
// host compiles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_orders_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

import '../templates/pages/driver/home/bottom_sheet_screen.dart';

const Size _phone = Size(390, 900);

/// Pump the sheet exactly where `home_page.dart` puts it: a direct child
/// of a `Stack` that also carries the (non-positioned) map, inside a
/// Scaffold body.
Future<void> _pumpSheet(WidgetTester tester, {bool isScrolling = false}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: _phone,
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                // Stands in for `_map(context, ref)` — the non-positioned
                // child the real Stack sizes itself from.
                const SizedBox.expand(),
                BottomSheetScreen(isScrolling: isScrolling),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final GetIt getIt = GetIt.instance;
    if (!getIt.isRegistered<CourierOrdersRepositoryFacade>()) {
      getIt.registerSingleton<CourierOrdersRepositoryFacade>(
        DemoCourierOrdersRepository(),
      );
    }
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('the driver home sheet lays out inside the home Stack', () {
    testWidgets('off duty - no infinite-width assert', (tester) async {
      await _pumpSheet(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on duty - no infinite-width assert', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'keyOnline': true,
      });
      await CourierStorage.init();
      await _pumpSheet(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tucked away while the map scrolls - still lays out', (
      tester,
    ) async {
      await _pumpSheet(tester, isScrolling: true);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the sheet spans the full width of the stack', (tester) async {
      await _pumpSheet(tester);
      expect(tester.takeException(), isNull);
      final Finder column = find
          .descendant(
            of: find.byType(BottomSheetScreen),
            matching: find.byType(Column),
          )
          .first;
      // Both horizontal edges pinned: the column is as wide as the phone,
      // never unbounded and never intrinsically sized.
      expect(tester.getSize(column).width, _phone.width);
    });
  });
}
