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

// The calculator's own mute (Ray: "calc must have mute on itself").
//
// Pinned here: it defaults to the old behaviour (unmuted, every press
// clicks); muted, NO calculator press reaches KeySound - pad keys, the
// double-tap on C and the memory pills alike; the choice survives a
// restart (it is read back from LocalStorage); a corrupt record reads as
// unmuted; and the toggle sits in the header of BOTH layouts.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:calc_sdk/calc_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double phoneWidth = 390;
const double tabletWidth = 1280;

int clicks = 0;

Future<void> _freshStore([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  await LocalStorage.init();
  CalcSound.reload();
}

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: Size(width, 900),
      builder: (context, _) =>
          const ProviderScope(child: MaterialApp(home: CalculatorView())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key).first);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final void Function() realPlayer = CalcSound.player;

  setUp(() async {
    AppStyle.isDark = true;
    clicks = 0;
    CalcSound.player = () => clicks++;
    await _freshStore();
  });

  tearDown(() => CalcSound.player = realPlayer);

  group('CalcSound', () {
    test('defaults to unmuted: a press clicks, as before', () {
      expect(CalcSound.isMuted, isFalse);
      CalcSound.tap();
      expect(clicks, 1);
    });

    test('muted, a press is silent', () async {
      await CalcSound.setMuted(true);
      CalcSound.tap();
      CalcSound.tap();
      expect(clicks, 0);
    });

    test('the choice persists and is read back after a restart', () async {
      await CalcSound.setMuted(true);
      expect(LocalStorage.getJson(CalcSound.storageKey), {'muted': true});
      // A "restart": the store re-opens with what was written.
      await LocalStorage.init();
      CalcSound.reload();
      expect(CalcSound.isMuted, isTrue);

      await CalcSound.toggle();
      CalcSound.reload();
      expect(CalcSound.isMuted, isFalse);
    });

    test('a corrupt record reads as unmuted', () async {
      await LocalStorage.setJson(CalcSound.storageKey, {'muted': 'yes'});
      CalcSound.reload();
      expect(CalcSound.isMuted, isFalse);
    });
  });

  for (final width in [phoneWidth, tabletWidth]) {
    final layout = width == phoneWidth ? 'phone fold' : 'two planes';
    // The memory-bar pills render only on the two-plane layout; the fold
    // keeps the pad's own memory row.
    final memoryKey = width == phoneWidth
        ? const Key('calcKeyM+')
        : const Key('calcMemoryPillM+');

    group('the header toggle ($layout)', () {
      testWidgets('renders unmuted by default and presses click', (
        tester,
      ) async {
        await _pump(tester, width);
        expect(find.byKey(const Key('calcMuteToggle')), findsOneWidget);
        expect(find.byKey(const Key('calcMuteIconOn')), findsOneWidget);
        await _tap(tester, const Key('calcKey7'));
        await _tap(tester, memoryKey);
        expect(clicks, 2);
      });

      testWidgets('muting silences keys and memory pills, and persists', (
        tester,
      ) async {
        await _pump(tester, width);
        await _tap(tester, const Key('calcMuteToggle'));
        expect(find.byKey(const Key('calcMuteIconOff')), findsOneWidget);
        expect(CalcSound.isMuted, isTrue);
        expect(LocalStorage.getJson(CalcSound.storageKey), {'muted': true});
        // The toggle itself never clicks.
        expect(clicks, 0);

        await _tap(tester, const Key('calcKey7'));
        await _tap(tester, const Key('calcKey+'));
        await _tap(tester, memoryKey);
        expect(clicks, 0);
        // ...while the pad still works.
        expect(find.text('7'), findsWidgets);

        await _tap(tester, const Key('calcMuteToggle'));
        expect(find.byKey(const Key('calcMuteIconOn')), findsOneWidget);
        await _tap(tester, const Key('calcKey8'));
        expect(clicks, 1);
      });

      testWidgets('a muted calculator reopens muted', (tester) async {
        await CalcSound.setMuted(true);
        await LocalStorage.init();
        CalcSound.reload();
        await _pump(tester, width);
        expect(find.byKey(const Key('calcMuteIconOff')), findsOneWidget);
        await _tap(tester, const Key('calcKey9'));
        expect(clicks, 0);
      });
    });
  }
}
