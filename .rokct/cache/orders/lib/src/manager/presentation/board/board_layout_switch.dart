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

import 'package:flutter/widgets.dart';

import 'package:base_sdk/src/presentation/adaptive/planes.dart';

/// Picks the orders workspace layout BY PLANE COUNT — the same rule the
/// plane host applies to the width it is given ([PlaneHost.planeCountFor]:
/// two planes from 600 logical px, three from 840).
///
/// The approved board (frame 33a) declares ALL planes, so it is the
/// layout whenever there are two or more planes to declare; the phone
/// list mode (33b) is the one-plane degradation. Keying this on
/// AdaptiveShell's `expanded` class (>= 840) left the 600..839 band —
/// the unfolded fold and the tour's 800 px tablet leg — on the list mode
/// while the plane host beneath was already granting two planes (tablet
/// store review 2026-09-02, still 12-order_queue).
///
/// Measured from the layout constraints, not the window: whatever a shell
/// reserves beside the page (the manager's start rail) is already taken
/// off, so this switch and the [PlaneHost] the wide layout builds agree
/// on the count by construction.
class BoardLayoutSwitch extends StatelessWidget {
  /// The one-plane layout (the phone list mode, 33b).
  final WidgetBuilder compact;

  /// The two-or-more-plane layout (the plane-hosted board, 33a/33d).
  final WidgetBuilder wide;

  const BoardLayoutSwitch({
    super.key,
    required this.compact,
    required this.wide,
  });

  /// True when [width] yields two planes or more.
  static bool isWide(double width) => PlaneHost.planeCountFor(width) >= 2;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          isWide(constraints.maxWidth) ? wide(context) : compact(context),
    );
  }
}
