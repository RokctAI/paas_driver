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

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'local_storage.dart';

/// Tells a real first open from coming back to the app (Ray, 2026-11-07:
/// "Can all or one [splash] be turned off if app is not opening from cold
/// start? Like if I go to another app and come back to it").
///
/// While the app runs in the background Android may close it to save
/// memory, and the next open starts it again from the splash. When the app
/// was in use less than [within] ago, that start is a return: the splash
/// page leaves at once, with no artwork and no pause (see SplashPage).
///
/// The time is written whenever the app goes to the background, so it says
/// when the person last had the app open, not when they last moved page.
/// It is written only after this run's boot reached a real page ([booted]):
/// an app put away while still on the splash (a fresh install waiting on
/// the network) has never loaded its settings, so its next start is a first
/// open. Closing the app on purpose (swiping it away from recent apps, when
/// Android reports it) forgets the time, so that next start is a first open
/// too. Android closing it in the background to save memory reports
/// nothing, so that start counts as a return.
class WarmReturn {
  WarmReturn._();

  static const storageKey = 'warm_return.v1';

  /// How long ago the app may have been open and still count as a return.
  static Duration within = const Duration(minutes: 30);

  static _Watcher? _watcher;
  static bool _booted = false;

  /// The splash calls this once boot has put a real page up.
  static void booted() => _booted = true;

  /// Whether this run's boot has put a real page up.
  static bool get hasBooted => _booted;

  /// Whether the app was open less than [within] ago. Read it at boot,
  /// before [watch] writes a fresh time.
  static bool recent({DateTime? now}) {
    final at = DateTime.tryParse((LocalStorage.getJson(storageKey)?['at'] ?? '').toString());
    if (at == null) return false;
    final gap = (now ?? DateTime.now()).difference(at);
    return !gap.isNegative && gap <= within;
  }

  /// Notes the time now. Called when the app goes to the background.
  static Future<void> mark({DateTime? now}) =>
      LocalStorage.setJson(storageKey, {'at': (now ?? DateTime.now()).toIso8601String()});

  /// Forgets the time: the next start is a first open.
  static Future<void> forget() => LocalStorage.setJson(storageKey, null);

  /// Starts noting the time each time the app goes to the background.
  /// Safe to call more than once.
  static void watch() {
    if (_watcher != null) return;
    final w = _watcher = _Watcher();
    WidgetsBinding.instance.addObserver(w);
  }

  /// For tests: stop watching.
  @visibleForTesting
  static void reset() {
    final w = _watcher;
    if (w != null) WidgetsBinding.instance.removeObserver(w);
    _watcher = null;
    _booted = false;
  }
}

class _Watcher with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(WarmReturn.forget());
    } else if (WarmReturn.hasBooted &&
        (state == AppLifecycleState.paused || state == AppLifecycleState.hidden)) {
      unawaited(WarmReturn.mark());
    }
  }
}
