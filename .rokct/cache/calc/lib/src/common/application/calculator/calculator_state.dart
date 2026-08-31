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

import '../../domain/result.dart';

/// Plain immutable state (no freezed) — this repo's SDKs do not ship
/// generated files (*.freezed.dart is gitignored) and a path-dep SDK cannot
/// rely on the host's build_runner run, so the freezed CalculatorState from
/// paas_manager lib/calc/state/ is folded into a hand-written class
/// (same call products_sdk made for its manager states).
class CalculatorState {
  const CalculatorState({
    this.display = '0',
    this.history = const [],
    this.memoryValue = 0,
  });

  /// What the display panel currently shows.
  final String display;

  /// Completed calculations, oldest first, capped at 10.
  final List<CalculationResult> history;

  /// Value held by the M+/M-/MR/MC memory keys.
  final double memoryValue;

  CalculatorState copyWith({
    String? display,
    List<CalculationResult>? history,
    double? memoryValue,
  }) =>
      CalculatorState(
        display: display ?? this.display,
        history: history ?? this.history,
        memoryValue: memoryValue ?? this.memoryValue,
      );
}
