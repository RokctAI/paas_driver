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

import 'package:auto_route/auto_route.dart';
import 'package:calc_sdk/calc_sdk.dart';
import 'package:flutter/material.dart';

/// The installed /calc route page — a thin wrapper around
/// [CalculatorView] (design strip section 45).
///
/// The route stays un-gated and app_type-free, so manager and driver
/// both get it (Ray's decision, recorded in this SDK's manifest).
///
/// PICK MODE is the whole of the wrapper's new job, and it is the fix
/// for section 45's flag (a): the shipped page popped with NO RESULT,
/// so every gate that wanted a number back — the till's quick-amount
/// chip (chip 843) and the deliveryman's "Count it" step (chip 845) —
/// was a gate to a dead end. A caller now asks for the number by ROUTE
/// PATH, never by importing this SDK (ADR-005):
///
/// ```dart
/// final picked = await context.router.pushNamed('/calc?pick=true');
/// if (picked is String) { /* fill YOUR amount field */ }
/// ```
///
/// The pop value is the calculator's display STRING; a caller that does
/// not ask gets the standalone screen and null back, exactly as before.
@RoutePage()
class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key, @QueryParam('pick') this.pick = false});

  /// True when the caller wants the number handed back (chip 840).
  final bool pick;

  @override
  Widget build(BuildContext context) {
    return CalculatorView(pickAmount: pick);
  }
}
