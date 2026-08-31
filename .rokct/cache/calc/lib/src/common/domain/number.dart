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
