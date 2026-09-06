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

// Design strip section 49 — chip 301 (the driver root tab set) and
// frame 49d's "SHIFT ENDED" stamp.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * the tab set is FIVE tabs in the drawn order — Home · Jobs · Route ·
//     Income · Profile. `DriverRootTab.index` is the pill's tab index,
//     so reordering the enum silently relabels every tap.
//   * the lit tab follows the STATE the page passes down: Home while
//     idling, Jobs while inside a job. Nothing is stored in the widget.
//   * every tap reports its tab, the lit one included — the host decides
//     what a tap on the lit tab means.
//   * the stamp never guesses: it names a shift that ended TODAY on this
//     phone, and says TODAY otherwise (no stamp, or yesterday's).

import 'package:base_sdk/src/presentation/components/floating_nav/bottom_navigator_item.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';
import 'package:delivery_sdk/src/driver/presentation/home/driver_root_nav.dart';
import 'package:delivery_sdk/src/driver/presentation/home/shift_stamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Size _phone = Size(390, 900);

/// Pump the nav exactly where `home_page.dart` puts it: a full-size slot
/// under a bottom-centre Align inside the page's Stack. The pill reads a
/// riverpod provider for its scroll-collapse signal, so a ProviderScope
/// is part of the frame it renders in.
Future<void> _pumpNav(
  WidgetTester tester, {
  required DriverRootTab current,
  required ValueChanged<DriverRootTab> onSelect,
}) async {
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
                const SizedBox.expand(),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: DriverRootNav(current: current, onSelect: onSelect),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

List<BottomNavigatorItem> _items(WidgetTester tester) => tester
    .widgetList<BottomNavigatorItem>(find.byType(BottomNavigatorItem))
    .toList();

void main() {
  group('chip 301 - the driver root tab set', () {
    test('five destinations, in the drawn order', () {
      expect(DriverRootTab.values, [
        DriverRootTab.home,
        DriverRootTab.jobs,
        DriverRootTab.route,
        DriverRootTab.income,
        DriverRootTab.profile,
      ]);
    });

    testWidgets('the pill carries exactly five tabs', (tester) async {
      await _pumpNav(tester, current: DriverRootTab.home, onSelect: (_) {});
      expect(tester.takeException(), isNull);
      final items = _items(tester);
      expect(items.length, 5);
      // One BottomNavigatorItem per tab, indexed in order.
      expect(items.map((i) => i.index).toList(), [0, 1, 2, 3, 4]);
    });

    testWidgets('Home is lit while the driver idles (49a/49d/49e)', (
      tester,
    ) async {
      await _pumpNav(tester, current: DriverRootTab.home, onSelect: (_) {});
      for (final item in _items(tester)) {
        expect(item.currentIndex, DriverRootTab.home.index);
      }
    });

    testWidgets('Jobs is lit while the driver is inside a job (49c)', (
      tester,
    ) async {
      await _pumpNav(tester, current: DriverRootTab.jobs, onSelect: (_) {});
      for (final item in _items(tester)) {
        expect(item.currentIndex, DriverRootTab.jobs.index);
      }
    });

    testWidgets('every tap reports its tab, the lit one included', (
      tester,
    ) async {
      final taps = <DriverRootTab>[];
      await _pumpNav(tester, current: DriverRootTab.home, onSelect: taps.add);
      for (final tab in DriverRootTab.values) {
        await tester.tap(
          find.byWidgetPredicate(
            (w) => w is BottomNavigatorItem && w.index == tab.index,
          ),
        );
        await tester.pump();
      }
      expect(taps, DriverRootTab.values);
    });

    testWidgets('the sheets leave real room under the pill', (tester) async {
      // Pumped so ScreenUtil is initialised: the clearance is the pill's
      // own height plus its float plus the drawn gap, never zero.
      await _pumpNav(tester, current: DriverRootTab.home, onSelect: (_) {});
      expect(driverRootNavClearance(), greaterThan(60));
    });
  });

  group('frame 49d - the SHIFT ENDED stamp', () {
    final noon = DateTime(2026, 8, 30, 12, 0);

    test('names the minute the shift ended today, upper-cased, as drawn', () {
      expect(
        shiftStampHeading(
          today: 'Today',
          shiftEnded: 'Shift ended',
          endedAt: DateTime(2026, 8, 30, 17, 4),
          now: DateTime(2026, 8, 30, 21, 30),
        ),
        'TODAY · SHIFT ENDED 17:04',
      );
    });

    test('says TODAY and nothing more when nothing was recorded', () {
      expect(
        shiftStampHeading(
          today: 'Today',
          shiftEnded: 'Shift ended',
          endedAt: null,
          now: noon,
        ),
        'TODAY',
      );
    });

    test("never shows an earlier day's shift as today's", () {
      expect(
        shiftStampHeading(
          today: 'Today',
          shiftEnded: 'Shift ended',
          endedAt: DateTime(2026, 8, 29, 23, 59),
          now: DateTime(2026, 8, 30, 0, 1),
        ),
        'TODAY',
      );
      expect(shiftEndedToday(DateTime(2026, 8, 29, 23, 59), noon), isFalse);
      expect(shiftEndedToday(DateTime(2026, 8, 30, 0, 0), noon), isTrue);
    });

    test('the timestamp survives a round trip and clears on null', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await CourierStorage.init();
      expect(CourierStorage.getShiftEndedAt(), isNull);

      final ended = DateTime(2026, 8, 30, 17, 4);
      await CourierStorage.setShiftEndedAt(ended);
      expect(CourierStorage.getShiftEndedAt(), ended);

      // Going on duty clears it, so a second shift's end is the one shown.
      await CourierStorage.setShiftEndedAt(null);
      expect(CourierStorage.getShiftEndedAt(), isNull);
    });

    test('a bad stored value reads as nothing, never a crash', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'keyShiftEndedAt': 'not a date',
      });
      await CourierStorage.init();
      expect(CourierStorage.getShiftEndedAt(), isNull);
    });
  });
}
