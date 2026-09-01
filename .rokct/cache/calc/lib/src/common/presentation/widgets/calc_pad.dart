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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../application/calculator/calculator_provider.dart';
import '../../domain/number.dart';
import '../../domain/operator.dart';
import 'calc_key.dart';

/// THE CALC PAD — the shipped six rows, re-tokened and NOT re-laid-out
/// (design strip frame 45a: "exactly the shipped six rows ...
/// re-tokened and not re-laid-out"; the fold 45e keeps every one of
/// them, "nothing is scaled down and no key is dropped").
///
/// Row for row this is the pad that shipped in calc_sdk 1.0.1:
///
///   MC MR M- M+      the memory row
///   C  ±  %  ÷       the function row, and the top of the operator
///   7  8  9  ×       column
///   4  5  6  -
///   1  2  3  +
///   0     .  =       `0` at flex 2, the shipped wide key
///
/// The fourth column (÷ × - + with = beneath) is CHIP 839 — the one
/// structural thing the calc pad has that the fleet money keypad
/// (chip 390) does not, and, per 45f, the reason the two pads share
/// dress but never layout.
class CalcPad extends ConsumerWidget {
  const CalcPad({super.key, this.keyHeight, this.gap});

  /// Row height. Null lets the pad fill the height it is given (the
  /// tablet pad plane); a value pins it (the phone fold, where the pad
  /// sits under a scrollable strip).
  final double? keyHeight;

  final double? gap;

  static const List<List<String>> rows = [
    ['MC', 'MR', 'M-', 'M+'],
    ['C', '±', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '-'],
    ['1', '2', '3', '+'],
    ['0', '.', '='],
  ];

  static const List<String> _memoryKeys = ['MC', 'MR', 'M-', 'M+'];
  static const List<String> _functionKeys = ['C', '±', '%'];

  /// Chip 839 — the operator column, `=` included.
  static const List<String> operatorColumn = ['÷', '×', '-', '+', '='];

  static CalcKeyKind kindOf(String label) {
    if (_memoryKeys.contains(label)) return CalcKeyKind.memory;
    if (operatorColumn.contains(label)) return CalcKeyKind.operator;
    if (_functionKeys.contains(label)) return CalcKeyKind.function;
    return CalcKeyKind.digit;
  }

  /// The shipped dispatch, unchanged — the notifier's behaviour is not
  /// touched by section 45 (frames 45a/45e: the two new elements just
  /// render state that was already there).
  void _onPressed(WidgetRef ref, String text) {
    final notifier = ref.read(calculatorProvider.notifier);
    if (const ['÷', '×', '-', '+'].contains(text)) {
      notifier.onOperatorPressed(CalculatorOperator(text));
    } else if (text == '=' || text == 'C') {
      notifier.onResultPressed(text);
    } else if (_memoryKeys.contains(text)) {
      notifier.onMemoryPressed(text);
    } else if (text == '±') {
      notifier.onNumberPressed(SymbolNumber());
    } else if (text == '.') {
      notifier.onNumberPressed(DecimalNumber());
    } else if (text == '%') {
      notifier.onPercentPressed();
    } else {
      notifier.onNumberPressed(NormalNumber(text));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double g = gap ?? 8.r;
    Widget row(List<String> labels) {
      final children = <Widget>[];
      for (var i = 0; i < labels.length; i++) {
        if (i > 0) children.add(SizedBox(width: g));
        final label = labels[i];
        children.add(
          CalcKey(
            label: label,
            kind: kindOf(label),
            // The shipped undiscoverable gesture, kept verbatim: a
            // double-tap on C wipes the tape. Chip 841 exposes it as a
            // visible button; it does not replace it.
            onDoubleTap: label == 'C'
                ? () => ref.read(calculatorProvider.notifier).clearHistory()
                : null,
            flex: label == '0' ? 2 : 1,
            onTap: () => _onPressed(ref, label),
          ),
        );
      }
      return Row(children: children);
    }

    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) children.add(SizedBox(height: g));
      final built = row(rows[i]);
      children.add(
        keyHeight == null
            ? Expanded(child: built)
            : SizedBox(height: keyHeight, child: built),
      );
    }
    return Column(
      mainAxisSize: keyHeight == null ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
