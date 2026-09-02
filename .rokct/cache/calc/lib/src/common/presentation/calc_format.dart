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

/// Number rendering for the calculator's own surfaces.
///
/// Deliberately NOT `AppHelpers.numberFormat`: that formatter prefixes
/// the tenant currency symbol, and the calculator is arithmetic, not
/// money (frame 45f: "Calc is arithmetic, not money entry"). This is
/// the same whole-number rule `CalculatorNotifier` already applies to
/// the display, kept in one place so the tape, the memory bar and the
/// display can never disagree.
class CalcFormat {
  CalcFormat._();

  static String number(num value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toString();
  }
}
