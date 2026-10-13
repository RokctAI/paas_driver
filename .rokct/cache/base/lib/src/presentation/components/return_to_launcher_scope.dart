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

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// BACK GOES TO THE LAUNCHER for a page the launcher opened in this app.
///
/// launch_sdk's floating nav opens other fleet apps straight on a page (a
/// calculator, the tasks) with `?from=launcher` on the route. Ray,
/// 2026-10-12, asked whether back on such a page brings him back to the
/// launcher; it did not: back popped the page inside this app (warm start:
/// onto whatever screen was there; cold start: nothing to pop at all).
///
/// Wrap the page in this with [enabled] true and every pop of its ROUTE -
/// the page's own back pill, a swipe, Android's back gesture - pops the
/// page (when there is anything under it, so the app does not reopen on it)
/// and then calls [SystemNavigator.pop], Android's own back for the
/// activity. base_sdk's shell is a FlutterFragmentActivity, so that goes
/// through the back dispatcher: from Android 12 a root launcher activity
/// moves to the background and keeps its state; before 12 it finishes.
/// Either way the launcher is what shows.
///
/// Pops INSIDE the page (a plane, a sheet) are not route pops and are
/// untouched. With [enabled] false this is just [child].
class ReturnToLauncherScope extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const ReturnToLauncherScope({
    super.key,
    required this.enabled,
    required this.child,
  });

  /// The query parameter value launch_sdk adds: `?from=launcher`.
  static const String fromLauncher = 'launcher';

  /// Whether a route's `from` query parameter says the launcher opened it.
  static bool requestedBy(String? from) => from == fromLauncher;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
        SystemNavigator.pop();
      },
      child: child,
    );
  }
}
