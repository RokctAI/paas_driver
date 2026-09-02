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

/// Binary operator for the calculator.
///
/// Ported unchanged from paas_manager lib/calc/operator.dart.
class CalculatorOperator {
  final String symbol;

  CalculatorOperator(this.symbol);

  num calculate(num first, num second) {
    switch (symbol) {
      case '÷':
        return first / second;
      case '×':
        return first * second;
      case '-':
        return first - second;
      case '+':
        return first + second;
      default:
        return 0;
    }
  }
}
