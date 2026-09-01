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

// THE /calc SCREEN — design strip section 45 (frames 45a, 45e, 45f;
// chips 836-841), the calculator surface redrawn in the settled plane
// language.
//
// What changed, and why each change is small:
//
//  * PLANES. /calc DECLARES TWO (frame 45a): the tape plane and the
//    display+pad plane. The shipped view jammed the history into a
//    `ListView` at the top-RIGHT of the display area at 60% of screen
//    width — at tablet size a sliver of grey text over empty space.
//    Given a plane it becomes a readable ledger. On a phone the plane
//    mechanism collapses by construction and the fold (frame 45e) takes
//    over: the memory value rides in the header pill slot, the tape
//    becomes a pullable strip of the last three with an honest count,
//    and the pad keeps ALL SIX SHIPPED ROWS at full width. Nothing is
//    scaled down and no key is dropped.
//
//  * TOKENS (flag (b)). The shipped view painted four raw hex
//    constants — 0xFF22252D background, 0xFF2A2D37 keys, 0xFFFF5A66
//    accent, 0xFF26F4CE function — and was the last screen in the fleet
//    not on `AppStyle`. They map one for one onto base tokens
//    (surfaceDark / cardDarkAlt / primary / green). The LAYOUT is
//    untouched: the same six rows, in the same order.
//
//  * SOUND (frame 45f). The pad now wears the fleet key tile, so every
//    press plays `KeySound.tap()` — the calculator was the one keypad
//    in the fleet still silent while `MoneyKeypad` (chip 390) has
//    clicked on every press since base_sdk 1.44.0. The sound lives in
//    the tile; wearing the tile buys it. The pads share DRESS, never
//    LAYOUT: 390 is 1-2-3-first money order, calc is 7-8-9-first
//    desktop order with an operator column, and neither may be
//    reordered to match the other.
//
//  * TWO INVISIBLE STATES MADE VISIBLE (flag (c)). `memoryValue` was
//    stored and never rendered (chip 838); `clearHistory()` was
//    reachable only by double-tapping C (chip 841). Both elements just
//    render or expose state that already existed — the notifier's
//    behaviour is unchanged, and the double-tap gesture stays.
//
//  * THE NUMBER COMES BACK (flag (a)). Both exits used to
//    `maybePop()` with NO RESULT, so every gate that wants a number was
//    a gate to a dead end. [CalculatorView.pickAmount] is the fix, and
//    it is deliberately tiny: in pick mode the pad plane grows one
//    primary pill (chip 840) that pops the current display back to the
//    caller. Callers reach it BY ROUTE PATH (`/calc?pick=true`) and
//    never import calc_sdk, so no SDK boundary is crossed (ADR-005) —
//    a caller on an older calc simply gets null back and falls through
//    to its own entry, which is why the till and the driver sheet can
//    ship this before or after us.

import 'package:base_sdk/src/presentation/adaptive/planes.dart';
import 'package:base_sdk/src/presentation/components/floating_nav/floating_bottom_nav.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import '../application/calculator/calculator_provider.dart';
import 'widgets/calc_memory_bar.dart';
import 'widgets/calc_pad.dart';
import 'widgets/calc_tape_pane.dart';

/// The /calc screen. Lives in lib (not only in the installed template)
/// so a composition can also embed it directly; the installed route
/// page is a thin wrapper.
class CalculatorView extends ConsumerWidget {
  const CalculatorView({super.key, this.pickAmount = false});

  /// PICK MODE (chip 840, frames 45c/45d): the caller asked this
  /// calculator for a NUMBER. The pad plane grows the "use this amount"
  /// pill, and tapping it pops the display string back to the caller.
  ///
  /// False — the default, and the whole of the standalone screen (45a /
  /// 45e) — pops nothing, exactly as the shipped page did.
  final bool pickAmount;

  /// The claim (frame 45a). Two planes: tape, and display+pad.
  static const PlaneSpan span = PlaneSpan.two;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppStyle.surfaceDark,
      body: GestureDetector(
        // The shipped swipe-right-to-pop, kept as a shortcut (frame
        // 45a) — the corner pill is the settled affordance, not its
        // replacement.
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 0) {
            Navigator.of(context).maybePop();
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              PlaneHost(
                stack: [
                  PlanePage(
                    name: 'calc',
                    span: span,
                    builder: (context) => _CalcBody(pickAmount: pickAmount),
                  ),
                ],
              ),
              // Chip 347 — the settled back affordance: bottom-END
              // corner, 16 logical in, popping this pushed page.
              PositionedDirectional(
                end: 16,
                bottom: 16,
                child: FloatingBackPill(
                  back: FloatingNavBack(
                    icon: Remix.arrow_left_s_line,
                    label: AppHelpers.getTranslation(TrKeys.back),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The screen's content, laid out on whatever planes it was granted.
class _CalcBody extends ConsumerWidget {
  const _CalcBody({required this.pickAmount});

  final bool pickAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planes = Planes.of(context);
    // The claim is two; a one-plane screen (phone), or a caller that
    // has already taken the other plane, folds (frame 45e).
    if (planes.span < 2) {
      return _Fold(pickAmount: pickAmount);
    }
    return Padding(
      padding: REdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _TapeColumn(pickAmount: pickAmount)),
          SizedBox(width: planes.gap),
          Expanded(child: _PadColumn(pickAmount: pickAmount)),
        ],
      ),
    );
  }
}

/// Plane 1 of the claim: the memory bar (838) over the tape pane (836)
/// over Clear the tape (841) — the order frame 45a draws.
class _TapeColumn extends StatelessWidget {
  const _TapeColumn({required this.pickAmount});

  final bool pickAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CalcMemoryBar(),
        12.verticalSpace,
        const Expanded(child: CalcTapePane()),
        12.verticalSpace,
        const CalcClearTapeButton(),
      ],
    );
  }
}

/// Plane 2 of the claim: the display, the pick pill when a caller asked
/// for a number (840), and the pad — the shipped six rows (839).
class _PadColumn extends ConsumerWidget {
  const _PadColumn({required this.pickAmount});

  final bool pickAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(calculatorProvider).display;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Display(display: display),
        if (pickAmount) ...[
          12.verticalSpace,
          CalcUseAmountButton(display: display),
        ],
        16.verticalSpace,
        const Expanded(child: CalcPad()),
      ],
    );
  }
}

/// The phone fold (frame 45e): the memory value in the header's count
/// pill slot, the tape as a pullable strip of the last three, the pad
/// at full width with every one of its six rows.
class _Fold extends ConsumerWidget {
  const _Fold({required this.pickAmount});

  final bool pickAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = ref.watch(calculatorProvider).display;
    return Padding(
      padding: REdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                AppHelpers.getTranslation(TrKeys.calculator),
                style: AppStyle.interSemi(size: 18),
              ),
              const Spacer(),
              const CalcMemoryBar(compact: true),
            ],
          ),
          12.verticalSpace,
          const CalcTapePane(compact: true),
          12.verticalSpace,
          _Display(display: display, size: 38),
          if (pickAmount) ...[
            10.verticalSpace,
            CalcUseAmountButton(display: display),
          ],
          12.verticalSpace,
          Expanded(child: CalcPad(gap: 8.r)),
          // Clearance for the corner back pill.
          64.verticalSpace,
        ],
      ),
    );
  }
}

/// The display panel — the shipped bottom-right big number, on tokens.
class _Display extends StatelessWidget {
  const _Display({required this.display, this.size = 48});

  final String display;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('calcDisplay'),
      width: double.infinity,
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Text(
        display,
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyle.interSemi(size: size),
      ),
    );
  }
}

/// CHIP 840 — "Use R470.00 as the amount".
///
/// Renders ONLY in pick mode: the standalone calculator (45a / 45e)
/// shows nothing, because nothing asked it for a number. The sub-line
/// is deliberately explicit — the amount lands in the CALLER'S amount
/// display and never touches a cart, an order or a balance.
class CalcUseAmountButton extends StatelessWidget {
  const CalcUseAmountButton({super.key, required this.display});

  /// The calculator's current display string — what pops back.
  final String display;

  /// Fills `{amount}` in the translated label, and falls back to
  /// appending the amount when the seeded copy has no placeholder (the
  /// humanized-key fallback has none).
  static String label(String amount) {
    final template = AppHelpers.getTranslation(TrKeys.useAsTheAmount);
    return template.contains('{amount}')
        ? template.replaceAll('{amount}', amount)
        : '$template $amount';
  }

  @override
  Widget build(BuildContext context) {
    final money = AppHelpers.numberFormat(
      number: double.tryParse(display) ?? 0,
    );
    return GestureDetector(
      key: const Key('calcUseAmount'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(display),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 50.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppStyle.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              label(money),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interSemi(size: 15, color: AppStyle.blackColor),
            ),
          ),
          6.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.fillsTheAmountNeverTheCart),
            textAlign: TextAlign.center,
            style: AppStyle.interNormal(
              size: 11,
              color: AppStyle.textDarkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
