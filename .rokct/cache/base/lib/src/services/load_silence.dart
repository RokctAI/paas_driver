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

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The one load-time silence rule (Ray, 2026-10-05: an auth or backend
/// error still showed when the app loaded, before he did anything).
///
/// Work the app starts by itself — splash, app start, a page's initState,
/// the language list, translations, the profile refresh — has no person
/// waiting on it, so its failures are debug output only. An error is shown
/// only for something the person did (a tap, a save, a pull-to-refresh),
/// and being offline is never an error either way.
bool shouldSurfaceLoadError({
  required bool userInitiated,
  bool offline = false,
}) =>
    userInitiated && !offline;

/// Debug-only record of a failure [shouldSurfaceLoadError] kept off screen.
void logSilencedLoadError(String where, Object? detail) {
  debugPrint('==> $where: silent load-time failure: $detail');
}

/// The backstop for [shouldSurfaceLoadError]: no error toast before the
/// person has done anything (Ray: being offline or logged out must never be
/// shown as an error; minilauncher 1.2.16 still showed a server error on the
/// splash / login screen when opened, or returned to, while signed out).
///
/// [shouldSurfaceLoadError] needs every load-time call site to say it is
/// load-time, and one that does not (or one added later) puts an error on
/// the splash or login screen again. This gate does not depend on the call
/// site. Once armed (by `BaseSdkDependencies.register`, so every composed
/// app has it), the error toasts in `AppHelpers` -
/// `showCheckTopSnackBar` (and through it `ErrorPresenter.show` /
/// `showTechnical` and auth_sdk's `AuthErrorPresenter`) and
/// `showNoConnectionSnackBar` - are dropped to debug output until the
/// person touches the screen or presses a key. Telemetry the presenters
/// send is unaffected.
///
/// A tap is a pointer-down, which arrives before the button's onTap runs,
/// so every error caused by something the person did still shows.
///
/// Resume: a return to the app counts as a fresh start when the person's
/// last touch is older than [staleAfter]. Nothing they did that long ago is
/// still waiting on an answer (requests time out in 30 seconds), so anything
/// that fails on the way back in is the app's own work. A shorter trip
/// keeps the last touch: signing in with Google or Apple hands the screen to
/// system UI and back, and a failed sign-in must still be shown.
///
/// Unarmed (unit tests, hosts that never call `BaseSdkDependencies`) the
/// gate passes everything, so nothing changes there.
abstract class LoadQuietGate {
  LoadQuietGate._();

  /// How old the person's last touch may be when the app comes back to the
  /// foreground and still count for what fails next.
  static const Duration staleAfter = Duration(minutes: 2);

  static bool _armed = false;
  static DateTime? _lastActedAt;
  static AppLifecycleListener? _lifecycle;

  /// Clock seam for tests.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /// Starts listening for the person's input. Safe to call more than once;
  /// fails open (stays unarmed) when there is no binding to listen on.
  static void arm() {
    if (_armed) return;
    try {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
      HardwareKeyboard.instance.addHandler(_onKey);
      _lifecycle = AppLifecycleListener(onResume: onResume);
      _lastActedAt = null;
      _armed = true;
    } catch (e) {
      debugPrint('==> LoadQuietGate: could not arm: $e');
    }
  }

  /// True while an error toast would show for nothing the person did.
  static bool get quiet => _armed && _lastActedAt == null;

  /// Call at the top of an error toast. Returns true (and logs [detail] to
  /// debug output) when the toast must not show.
  static bool suppress(String where, Object? detail) {
    if (!quiet) return false;
    logSilencedLoadError(where, detail);
    return true;
  }

  /// The app came back to the foreground.
  @visibleForTesting
  static void onResume() {
    final DateTime? last = _lastActedAt;
    if (last != null && now().difference(last) > staleAfter) {
      _lastActedAt = null;
    }
  }

  /// Records the person's input as if they had touched the screen.
  @visibleForTesting
  static void markActed() => _lastActedAt = now();

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) markActed();
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) markActed();
    return false;
  }

  @visibleForTesting
  static void resetForTesting() {
    if (_armed) {
      try {
        GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
        HardwareKeyboard.instance.removeHandler(_onKey);
      } catch (_) {}
      _lifecycle?.dispose();
    }
    _lifecycle = null;
    _armed = false;
    _lastActedAt = null;
    now = DateTime.now;
  }
}
