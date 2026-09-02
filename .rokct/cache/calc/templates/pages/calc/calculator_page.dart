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
