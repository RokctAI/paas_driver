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

import 'operator.dart';

/// A single in-progress or completed calculation.
///
/// Ported unchanged from paas_manager lib/calc/result.dart. Kept mutable on
/// purpose: the notifier uses one instance as its working scratchpad and
/// snapshots it into history via [CalculationResult.from].
class CalculationResult {
  String? firstNum;
  String? secondNum;
  CalculatorOperator? operator;
  num? result;
  bool complete = false;

  CalculationResult();

  CalculationResult.from(CalculationResult other) {
    firstNum = other.firstNum;
    secondNum = other.secondNum;
    operator = other.operator;
    result = other.result;
    complete = other.complete;
  }
}
