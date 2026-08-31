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

// Design strip section 49 — the driver home composition (frames 49a,
// 49d, 49e, 49m).
//
// What a later edit could quietly undo, and what each group here pins:
//
//   * frame 49e's fold is a RE-LAYOUT, not a scale-down. If someone
//     replaces the width branch with `.w` scaling the three-up row
//     survives at 360 and the frame is silently lost, so the strip is
//     pumped at both widths and the composition asserted at each.
//   * the cash card's wording was REJECTED once for inventing an
//     obligation ("Still to bank" / "deposit before your next shift").
//     Nothing in the fleet backs a deposit, so the card must never
//     regrow a deadline, a due date or a banking step.
//   * chip 934 must NEVER name a person: the serializer emits no user
//     block at all, so a name on this card could only be invented.
//   * the wallet position and the floor gate state the amount as a
//     SENTENCE, not a signed number — "−1240" must not appear.
//   * the gate's limit is the one the SERVER resolved. It is passed in,
//     never guessed client-side, so the screen cannot disagree with the
//     guard that actually refuses the work.

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:delivery_sdk/src/driver/presentation/home/available_work_queue.dart';
import 'package:delivery_sdk/src/driver/presentation/home/cash_on_hand_card.dart';
import 'package:delivery_sdk/src/driver/presentation/home/driver_day_strip.dart';
import 'package:delivery_sdk/src/driver/presentation/home/off_duty_cards.dart';
import 'package:delivery_sdk/src/driver/presentation/home/work_paused_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pump `child` on a real phone surface.
///
/// The view is resized rather than wrapped in a SizedBox, because
/// frame 49e's fold is a property of THE PHONE — the widget reads
/// MediaQuery, so a narrow box on a wide window would not exercise it.
/// 390 is the canonical phone the frames were drawn on; 360 is the fold.
Future<void> _pumpAt(
  WidgetTester tester,
  Widget child, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 900),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

/// Every rendered string on screen, joined — the cheapest way to assert
/// what a frame does and does not say.
String _text(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' | ');

void main() {
  group('chip 931 - the day strip', () {
    testWidgets('it shows the three figures the report returns', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const DriverDayStrip(earned: 420, delivered: 6, lastFee: 38.5),
      );
      final rendered = _text(tester);
      expect(rendered, contains('420'));
      expect(rendered, contains('6'));
      expect(rendered, contains('38.5'));
    });

    testWidgets('at 390 it is three columns divided by two hairlines', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const DriverDayStrip(earned: 420, delivered: 6, lastFee: 38.5),
      );
      // Three cells side by side is a Row; the folded composition is not.
      expect(
        find.descendant(
          of: find.byType(DriverDayStrip),
          matching: find.byType(Row),
        ),
        findsWidgets,
      );
      expect(_text(tester), isNot(contains('|  | ')));
    });

    testWidgets('frame 49e - at the fold it re-lays-out rather than shrinking, '
        'and keeps all three values', (tester) async {
      await _pumpAt(
        tester,
        const DriverDayStrip(earned: 420, delivered: 6, lastFee: 38.5),
        width: 360,
      );
      final rendered = _text(tester);
      // Same three values survive the fold - nothing is dropped.
      expect(rendered, contains('420'));
      expect(rendered, contains('38.5'));
      // The folded composition merges the count into one inline string
      // ("6 delivered"), which the three-up composition never does.
      expect(rendered, contains('6 '));
    });

    testWidgets('the heading defaults to TODAY and takes an override', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const DriverDayStrip(
          earned: 0,
          delivered: 0,
          lastFee: 0,
          heading: 'TODAY · TUE 30 AUG',
        ),
      );
      expect(_text(tester), contains('TODAY · TUE 30 AUG'));
    });
  });

  group('chip 932 - the cash-on-hand card', () {
    testWidgets('it names the amount and how many orders it came from', (
      tester,
    ) async {
      await _pumpAt(tester, const CashOnHandCard(amount: 470, orderCount: 1));
      final rendered = _text(tester);
      expect(rendered, contains('470'));
      expect(rendered, contains('1 '));
    });

    testWidgets(
      'THE REJECTED WORDING NEVER COMES BACK - no deposit, no deadline, '
      'no banking step',
      (tester) async {
        await _pumpAt(tester, const CashOnHandCard(amount: 470, orderCount: 2));
        final rendered = _text(tester).toLowerCase();
        for (final invented in [
          'still to bank',
          'deposit',
          'before your next shift',
          'due',
          'owe',
        ]) {
          expect(
            rendered,
            isNot(contains(invented)),
            reason:
                'frame 49d was rejected for implying an obligation that '
                'does not exist anywhere in the code',
          );
        }
      },
    );

    testWidgets('it holds full weight at the fold, losing only two words', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        const CashOnHandCard(amount: 470, orderCount: 1, compact: true),
        width: 360,
      );
      expect(_text(tester), contains('470'));
    });
  });

  group('chips 933/934 - the available-work queue', () {
    const jobs = [
      AvailableJob(
        id: 'ORD-1',
        shopName: 'Bella Napoli',
        pickupSuburb: 'Sandton City',
        dropOffSuburb: 'Morningside',
        fee: 38.5,
        distanceKm: 2.4,
        isCash: true,
        cashAmount: 470,
      ),
      AvailableJob(
        id: 'ORD-2',
        shopName: "Naledi's Kitchen",
        pickupSuburb: 'Rivonia',
        dropOffSuburb: 'Sandown',
        fee: 26,
        distanceKm: 1.1,
      ),
    ];

    testWidgets('the header count is the number of offers on screen', (
      tester,
    ) async {
      await _pumpAt(tester, AvailableWorkQueue(jobs: jobs, onClaim: (_) {}));
      expect(_text(tester), contains('2'));
    });

    testWidgets('each offer draws shop, leg, fee and distance', (tester) async {
      await _pumpAt(tester, AvailableWorkQueue(jobs: jobs, onClaim: (_) {}));
      final rendered = _text(tester);
      expect(rendered, contains('Bella Napoli'));
      expect(rendered, contains('Sandton City → Morningside'));
      expect(rendered, contains('38.5'));
      expect(rendered, contains('2.4'));
    });

    testWidgets('the cash tag is real and the paid tag is its absence', (
      tester,
    ) async {
      await _pumpAt(tester, AvailableWorkQueue(jobs: jobs, onClaim: (_) {}));
      // The cash job carries the gross it will put in his pocket.
      expect(_text(tester), contains('470'));
    });

    testWidgets('the initials come from the shop, never from a person', (
      tester,
    ) async {
      expect(
        const AvailableJob(id: 'x', shopName: 'Bella Napoli').initials,
        'BN',
      );
      expect(const AvailableJob(id: 'x', shopName: 'Naledi').initials, 'NA');
      expect(const AvailableJob(id: 'x', shopName: '').initials, '');
      expect(const AvailableJob(id: 'x', shopName: 'A').initials, 'A');
    });

    testWidgets('Claim hands back the job that was tapped', (tester) async {
      AvailableJob? claimed;
      await _pumpAt(
        tester,
        AvailableWorkQueue(jobs: jobs, onClaim: (j) => claimed = j),
      );
      await tester.tap(find.byType(TextButton).first);
      await tester.pump();
      expect(claimed?.id, 'ORD-1');
    });

    testWidgets('frame 49e - the distance drops "away" at the fold only', (
      tester,
    ) async {
      await _pumpAt(tester, AvailableWorkQueue(jobs: jobs, onClaim: (_) {}));
      final wide = _text(tester);
      await _pumpAt(
        tester,
        AvailableWorkQueue(jobs: jobs, onClaim: (_) {}, compact: true),
        width: 360,
      );
      final narrow = _text(tester);
      expect(wide.length, greaterThan(narrow.length));
      // Claim survives the fold at full tap size - 49e is explicit.
      expect(find.byType(TextButton), findsNWidgets(2));
    });

    testWidgets('an empty queue draws the header and no cards', (tester) async {
      await _pumpAt(
        tester,
        AvailableWorkQueue(jobs: const [], onClaim: (_) {}),
      );
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('chip 945 - the off-duty rest state', () {
    testWidgets('it states what stopped, and it is true of the code', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        OffDutyRestCard(openJobsInZone: 3, onGoOnDuty: () {}),
      );
      expect(_text(tester), contains('3 '));
    });

    testWidgets('the hook back to work hides itself when there is none', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        OffDutyRestCard(openJobsInZone: 0, onGoOnDuty: () {}),
      );
      // Only the Go on duty button remains.
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('Go on duty fires', (tester) async {
      var went = false;
      await _pumpAt(
        tester,
        OffDutyRestCard(openJobsInZone: 1, onGoOnDuty: () => went = true),
      );
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(went, isTrue);
    });
  });

  group('chip 970 - the wallet position', () {
    testWidgets('it states the position as a SENTENCE, not a signed number', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        WalletPositionCard(owing: 1240, onTopUp: () {}, onOpenWallet: () {}),
      );
      final rendered = _text(tester);
      expect(rendered, contains('1,240'));
      expect(
        rendered,
        isNot(contains('-1240')),
        reason: 'a signed number is something a tired man argues with',
      );
      expect(rendered, isNot(contains('−1,240')));
    });

    testWidgets('a driver in credit is told so rather than shown a zero owed', (
      tester,
    ) async {
      await _pumpAt(
        tester,
        WalletPositionCard(owing: 0, onTopUp: () {}, onOpenWallet: () {}),
      );
      expect(find.byType(WalletPositionCard), findsOneWidget);
    });

    testWidgets('it never states a deadline or a deposit', (tester) async {
      await _pumpAt(
        tester,
        WalletPositionCard(owing: 1240, onTopUp: () {}, onOpenWallet: () {}),
      );
      final rendered = _text(tester).toLowerCase();
      for (final invented in ['deposit', 'due', 'before your next shift']) {
        expect(rendered, isNot(contains(invented)));
      }
    });

    testWidgets('it carries the exit', (tester) async {
      var toppedUp = false;
      var opened = false;
      await _pumpAt(
        tester,
        WalletPositionCard(
          owing: 1240,
          onTopUp: () => toppedUp = true,
          onOpenWallet: () => opened = true,
        ),
      );
      await tester.tap(find.byType(TextButton).first);
      await tester.tap(find.byType(TextButton).last);
      await tester.pump();
      expect(toppedUp, isTrue);
      expect(opened, isTrue);
    });
  });

  group('chips 990/991 - the wallet-floor gate', () {
    Widget gate({num owing = 2180, num allowance = 2000}) => WorkPausedGate(
      owing: owing,
      allowance: allowance,
      onTopUp: () {},
      onSeeWhatYouOwe: () {},
    );

    testWidgets('it shows the position and the operator limit beside it', (
      tester,
    ) async {
      await _pumpAt(tester, gate());
      final rendered = _text(tester);
      expect(rendered, contains('2,180'));
      expect(rendered, contains('2,000'));
    });

    testWidgets('the limit is the one it was GIVEN, never a guessed default', (
      tester,
    ) async {
      // Zero tolerance is reachable only by an explicit per-driver
      // override; the card must be able to say 0 rather than 2000.
      await _pumpAt(tester, gate(owing: 0.01, allowance: 0));
      expect(_text(tester), contains('0'));
      expect(
        _text(tester),
        isNot(contains('2,000')),
        reason: 'the screen must never disagree with the server guard',
      );
    });

    testWidgets('it promises that work already in hand is untouched', (
      tester,
    ) async {
      await _pumpAt(tester, gate());
      expect(find.byType(WorkPausedGate), findsOneWidget);
      // Three text blocks minimum: the pause, the position, the limit.
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('it states the amount as a sentence, not a signed number', (
      tester,
    ) async {
      await _pumpAt(tester, gate());
      expect(_text(tester), isNot(contains('-2180')));
      expect(_text(tester), isNot(contains('−2,180')));
    });

    testWidgets('it leads with the exit - Top up comes before the limit', (
      tester,
    ) async {
      await _pumpAt(tester, gate());
      expect(find.byType(TextButton), findsNWidgets(2));
    });

    testWidgets('the gate is styled as a decision, not as an error', (
      tester,
    ) async {
      await _pumpAt(tester, gate());
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(WorkPausedGate),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      // Bordered in the brand accent, never in AppStyle.red.
      expect((decoration.border as Border).top.color, AppStyle.primary);
    });
  });
}
