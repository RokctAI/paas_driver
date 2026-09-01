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

// FRAME 49b of design strip section 49 — the push offer as a decision.
//
// The four things a later edit could quietly undo:
//
//   * the DARK dress — the offer is the last screen a driver reads
//     under time pressure and it was the last white card on his path;
//   * the honest line. The ring looks like a hold on the job. It is
//     not, and nothing in the shipped screen said so;
//   * both legs NAMED — pickup and drop-off, not two anonymous avatars
//     joined by dots;
//   * the ring owning no clock. It draws a percent it is handed; the
//     shipped timer maths stays in the page.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:delivery_sdk/src/driver/presentation/widgets/push_offer_decision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:percent_indicator/percent_indicator.dart';

Widget _host(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 900),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: child),
      ),
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_host(child));
  await tester.pumpAndSettle();
}

const _legs = PushOfferLegs(
  pickup: PushOfferLeg(
    title: 'Karoo Kitchen',
    subtitle: '№ 4211',
    trailing: '14:05',
  ),
  dropOff: PushOfferLeg(
    title: '12 Mopani Street',
    subtitle: 'Thandi M.',
    trailing: '000 000 0000',
  ),
);

String _text(WidgetTester tester, Key within) => tester
    .widgetList<Text>(
      find.descendant(of: find.byKey(within), matching: find.byType(Text)),
    )
    .map((t) => t.data ?? '')
    .join(' | ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppStyle.isDark = true);

  group('the countdown', () {
    testWidgets('draws the percent it is handed and owns no clock',
        (tester) async {
      await _pump(
        tester,
        const PushOfferCountdown(percent: 0.4, label: '12 sec'),
      );
      final ring = tester.widget<CircularPercentIndicator>(
        find.byType(CircularPercentIndicator),
      );
      expect(ring.percent, closeTo(0.4, 0.0001));
      expect(find.text('12 sec'), findsOneWidget);
    });

    testWidgets('an out-of-range percent is clamped, never thrown',
        (tester) async {
      // The shipped maths divides the timer's leading number by the
      // configured delivery time; a server that shortens that setting
      // mid-offer can hand this widget a number above 1.
      await _pump(
        tester,
        const PushOfferCountdown(percent: 1.8, label: '90 sec'),
      );
      final ring = tester.widget<CircularPercentIndicator>(
        find.byType(CircularPercentIndicator),
      );
      expect(ring.percent, 1.0);
    });

    testWidgets('the collar is the sheet surface, not white', (tester) async {
      await _pump(
        tester,
        const PushOfferCountdown(percent: 0.5, label: '15 sec'),
      );
      final collar = tester
          .widget<Container>(find.byKey(const Key('pushOfferCountdown')));
      final fill = (collar.decoration! as BoxDecoration).color;
      expect(fill, AppStyle.cardDark);
      expect(fill, isNot(AppStyle.white));
    });
  });

  group('the honest line', () {
    testWidgets('the note is drawn and reads as a note, not a heading',
        (tester) async {
      await _pump(tester, const PushOfferTimerNote());
      expect(find.byKey(const Key('pushOfferTimerNote')), findsOneWidget);
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('pushOfferTimerNote')),
          matching: find.byType(Text),
        ),
      );
      expect(text.data, isNotEmpty);
      expect(text.style!.color, AppStyle.textDarkFaint);
    });
  });

  group('the two legs', () {
    testWidgets('both legs are drawn and both are named', (tester) async {
      await _pump(tester, _legs);
      expect(find.byKey(const Key('pushOfferLegs')), findsOneWidget);
      expect(find.byKey(const Key('pushOfferLegPickup')), findsOneWidget);
      expect(find.byKey(const Key('pushOfferLegDropOff')), findsOneWidget);
    });

    testWidgets('the pickup leg carries the shop, the order and the time',
        (tester) async {
      await _pump(tester, _legs);
      final line = _text(tester, const Key('pushOfferLegPickup'));
      expect(line, contains('Karoo Kitchen'));
      expect(line, contains('4211'));
      expect(line, contains('14:05'));
    });

    testWidgets('the drop-off leg carries the address, the name and the phone',
        (tester) async {
      await _pump(tester, _legs);
      final line = _text(tester, const Key('pushOfferLegDropOff'));
      expect(line, contains('12 Mopani Street'));
      expect(line, contains('Thandi M.'));
      expect(line, contains('000 000 0000'));
    });

    testWidgets('a leg with nothing under its title draws no subtitle row',
        (tester) async {
      await _pump(
        tester,
        const PushOfferLegs(
          pickup: PushOfferLeg(title: 'Karoo Kitchen'),
          dropOff: PushOfferLeg(title: '12 Mopani Street'),
        ),
      );
      // Label + title only, on each leg.
      expect(
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(const Key('pushOfferLegPickup')),
                matching: find.byType(Text),
              ),
            )
            .length,
        2,
      );
    });

    testWidgets('a leg with no image still draws its avatar well',
        (tester) async {
      await _pump(tester, _legs);
      expect(find.byIcon(Icons.image), findsNothing);
      expect(find.byKey(const Key('pushOfferLegPickup')), findsOneWidget);
    });
  });
}
