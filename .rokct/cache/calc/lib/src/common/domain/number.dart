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

/// Digit / input-symbol behaviors for the calculator keypad.
///
/// Ported from paas_manager lib/calc/number.dart (Ray: calc is saved as its
/// own SDK for the manager and driver compositions).
abstract class Number {
  String get display;
  String apply(String original);
}

class NormalNumber extends Number {
  @override
  final String display;

  NormalNumber(this.display);

  @override
  String apply(String original) {
    return original == '0' ? display : original + display;
  }
}

class SymbolNumber extends Number {
  @override
  String get display => '+/-';

  @override
  String apply(String original) {
    int index = original.indexOf('-');
    if (index == -1 && original != '0') {
      return '-$original';
    } else {
      return original.replaceFirst(RegExp(r'-'), '');
    }
  }
}

class DecimalNumber extends Number {
  @override
  String get display => '.';

  @override
  String apply(String original) {
    int index = original.indexOf('.');
    if (index == -1) {
      return '$original.';
    } else if (index == original.length - 1) {
      return original.substring(0, original.length - 1);
    } else {
      return original;
    }
  }
}
