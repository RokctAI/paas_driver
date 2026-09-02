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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import '../../application/calculator/calculator_provider.dart';
import '../../domain/result.dart';
import '../calc_format.dart';

/// CHIP 836 — THE HISTORY TAPE PANE, and CHIP 837 — its rows.
///
/// What shipped in calc_sdk 1.0.1 was a `ListView` jammed into the
/// top-right corner of the display area at 60% of screen width: at
/// tablet size, a sliver of grey text floating over empty space. Frame
/// 45a gives it a real plane and it becomes a readable ledger — header,
/// the cap stated ON the pane rather than hidden in a caption, then
/// hairline-separated rows, OLDEST AT THE TOP.
///
/// Chip 837, the row, keeps the shipped render format verbatim —
/// `firstNum op secondNum = result` — with the expression in secondary
/// ink, the result at 15px semi, and a trailing reuse glyph. Tapping a
/// row puts its result back on the display: the ONE new behaviour on
/// the tape, and a pure client change — it makes exactly the assignment
/// `onMemoryPressed('MR')` already makes.
///
/// The phone fold (frame 45e) renders the same pane [compact]: the last
/// three rows in a strip that still scrolls to the rest, with an HONEST
/// "3 / 10" line rather than a silent truncation, and no clear button —
/// chip 841 belongs to the full pane.
class CalcTapePane extends ConsumerWidget {
  const CalcTapePane({super.key, this.compact = false});

  /// The phone fold's strip form (frame 45e).
  final bool compact;

  /// The shipped cap (`CalculatorNotifier._addToHistory`).
  static const int historyCap = 10;

  /// How many rows the folded strip shows before it has to be pulled.
  static const int compactVisibleRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(calculatorProvider).history;
    final notifier = ref.read(calculatorProvider.notifier);
    // Oldest at the top — the shipped list order, no longer reversed
    // into a corner.
    final shown = compact && history.length > compactVisibleRows
        ? history.sublist(history.length - compactVisibleRows)
        : history;

    final header = Row(
      children: [
        Text(
          AppHelpers.getTranslation(TrKeys.tape),
          style: AppStyle.interSemi(size: 15),
        ),
        8.horizontalSpace,
        Container(
          key: const Key('calcTapeCountPill'),
          padding: REdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppStyle.cardDarkAlt,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppStyle.strokeDarkSubtle),
          ),
          child: Text(
            compact
                ? '${shown.length} / $historyCap'
                : '${history.length} / $historyCap',
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ),
      ],
    );

    // The cap, said out loud on the pane (frame 45a) instead of hiding
    // in a caption — and on the fold it is what keeps the truncation
    // honest (frame 45e).
    final capLine = Text(
      AppHelpers.getTranslation(TrKeys.tapeKeepsLast10),
      style: AppStyle.interNormal(
        size: 11,
        color: AppStyle.textDarkFaint,
      ),
    );

    final rows = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1.h,
          thickness: 1,
          color: AppStyle.strokeDarkSubtle,
        ));
      }
      rows.add(_TapeRow(
        result: shown[i],
        onTap: () => notifier.recallResult(shown[i]),
      ));
    }

    final list = rows.isEmpty
        ? const SizedBox.shrink()
        : ListView(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            shrinkWrap: compact,
            children: rows,
          );

    return Container(
      key: const Key('calcTapePane'),
      padding: REdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          header,
          6.verticalSpace,
          capLine,
          12.verticalSpace,
          if (compact)
            // The pullable strip: three rows tall, still scrollable to
            // the full ten.
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 132.h),
              child: list,
            )
          else
            Expanded(child: list),
        ],
      ),
    );
  }
}

/// CHIP 837 — one tape row.
class _TapeRow extends StatelessWidget {
  const _TapeRow({required this.result, required this.onTap});

  final CalculationResult result;
  final VoidCallback onTap;

  /// The SHIPPED render format, unchanged.
  String get expression =>
      '${result.firstNum} ${result.operator?.symbol} ${result.secondNum} =';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('calcTapeRow'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: REdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                expression,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.interNormal(
                  size: 13,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ),
            8.horizontalSpace,
            Text(
              CalcFormat.number(result.result ?? 0),
              style: AppStyle.interSemi(size: 15),
            ),
            6.horizontalSpace,
            Icon(
              Remix.arrow_go_back_line,
              size: 14.r,
              color: AppStyle.textDarkFaint,
            ),
          ],
        ),
      ),
    );
  }
}

/// CHIP 841 — CLEAR THE TAPE.
///
/// `clearHistory()` shipped reachable only by DOUBLE-TAPPING the C key
/// — a gesture nobody will ever find (frame 45a, flag (c)). This is the
/// visible form of it: a ghost button under the tape pane. The gesture
/// stays exactly as it was; this does not replace it, and neither
/// element changes the notifier's behaviour.
///
/// Deliberately absent from the phone fold (frame 45e): the clear
/// button belongs to the full tape pane.
class CalcClearTapeButton extends ConsumerWidget {
  const CalcClearTapeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empty = ref.watch(calculatorProvider).history.isEmpty;
    return GestureDetector(
      key: const Key('calcClearTape'),
      behavior: HitTestBehavior.opaque,
      onTap: empty
          ? null
          : () => ref.read(calculatorProvider.notifier).clearHistory(),
      child: Container(
        width: double.infinity,
        padding: REdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppStyle.strokeDarkSubtle),
        ),
        child: Text(
          AppHelpers.getTranslation(TrKeys.clearTheTape),
          style: AppStyle.interNormal(
            size: 13,
            color: empty ? AppStyle.textDarkFaint : AppStyle.textDarkSecondary,
          ),
        ),
      ),
    );
  }
}
