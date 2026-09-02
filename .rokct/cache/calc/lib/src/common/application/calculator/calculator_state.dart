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
