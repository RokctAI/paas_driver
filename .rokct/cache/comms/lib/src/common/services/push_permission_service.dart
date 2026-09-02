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


// compliance-ignore-file: obs-flutter-trace
// False positive: this file makes no outgoing HTTP calls — it asks the
// firebase_messaging plugin for the OS notification-permission prompt.
// Flagged solely because its path contains 'services'; there is no request
// to stamp with a trace id.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Signature of the platform call behind [PushPermissionService.request].
///
/// Exists so tests can stand in for `firebase_messaging` — `flutter_test`
/// has no Firebase app to talk to.
typedef PushPermissionRequest = Future<NotificationSettings?> Function({
  required bool sound,
  required bool alert,
  required bool badge,
});

/// The one place a composed app asks for the OS notification permission.
///
/// comms_sdk is the push owner in every composition (see the manifest's
/// `_comment_platform_permissions`), so the guard around
/// `FirebaseMessaging.requestPermission` lives here instead of being
/// re-typed at each shell's call site.
///
/// It carries BOTH halves of the fleet guard idiom established by comms'
/// own `comms-firebase-fcm-boot` boot hook — platform allowlist plus
/// fail-open try/catch — and adds the one thing that hook never needed:
///
/// 1. **Platform allowlist.** `firebase_messaging` has no Windows/Linux
///    implementation, and on desktop Firebase is (correctly) never
///    initialized, so touching `FirebaseMessaging.instance` throws
///    `[core/no-app]`. Android/iOS/macOS only, never web. Windows takes the
///    `DesktopNotificationPoller` path instead. Unchanged from the hook.
///
/// 2. **Fail-open try/catch.** A permission failure debugPrints; it never
///    propagates. The detail goes to the debug log, the app keeps running.
///
/// 3. **In-flight de-duplication.** The platform channel refuses concurrent
///    requests — `MethodChannelFirebaseMessaging.requestPermission` throws
///    `[firebase_messaging/unknown] A request for permissions is already
///    running, please wait for it to finish before doing another request.`
///    A second sign-in inside one process (the guided tour signs out and
///    back in; a real user can do the same) re-mounts the shell and fires a
///    second request while the first is still pending on the OS prompt.
///    A concurrent caller therefore JOINS the pending request instead of
///    starting a second one. The first request is never suppressed — a
///    single sign-in behaves exactly as it did before this class existed.
///
/// The pending state is cleared in a `finally`, so a denied, failed or
/// thrown first request can never latch the guard and leave notification
/// permissions permanently un-requestable for the rest of the process.
///
/// Note the shape of the bug this closes: the shell call sites did not
/// `await` the request, so the FirebaseException surfaced as an UNCAUGHT
/// async error that their surrounding try/catch could not see (in
/// `flutter test` that is a hard test failure). Routing through this class
/// puts the catch on the future itself, where it can actually run.
class PushPermissionService {
  PushPermissionService._();

  /// The in-flight request, or null when none is running.
  static Future<NotificationSettings?>? _pending;

  /// Test seam: replaces the real platform call. Never set in production
  /// code — `flutter_test` has no Firebase app to talk to.
  @visibleForTesting
  static PushPermissionRequest? platformRequestOverride;

  /// True while a permission request is outstanding.
  @visibleForTesting
  static bool get isRequestInFlight => _pending != null;

  /// Drops any pending/override state between tests.
  @visibleForTesting
  static void resetForTest() {
    _pending = null;
    platformRequestOverride = null;
  }

  /// Half one of the guard idiom, verbatim from comms'
  /// `comms-firebase-fcm-boot` hook body: android/iOS/macOS, never web.
  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Requests the OS notification permission, at most once at a time.
  ///
  /// Returns the granted [NotificationSettings], or null when the platform
  /// cannot be asked or the request failed. Never throws, so callers may
  /// fire it without awaiting exactly as the shells do today.
  static Future<NotificationSettings?> request({
    bool sound = true,
    bool alert = true,
    bool badge = false,
  }) {
    if (!isSupportedPlatform) {
      return Future<NotificationSettings?>.value(null);
    }

    final Future<NotificationSettings?>? inFlight = _pending;
    if (inFlight != null) {
      // Someone is already at the OS prompt. Join them; asking again is
      // what makes the platform channel throw.
      return inFlight;
    }

    // _pending is published BEFORE the request starts, so the `finally`
    // inside _run always clears the same entry it set — a request that
    // fails before its first suspension cannot leave the guard latched.
    final Completer<NotificationSettings?> completer =
        Completer<NotificationSettings?>();
    _pending = completer.future;
    _run(sound: sound, alert: alert, badge: badge)
        .then((NotificationSettings? settings) => completer.complete(settings));
    return completer.future;
  }

  static Future<NotificationSettings?> _run({
    required bool sound,
    required bool alert,
    required bool badge,
  }) async {
    try {
      final PushPermissionRequest? override = platformRequestOverride;
      if (override != null) {
        return await override(sound: sound, alert: alert, badge: badge);
      }
      return await FirebaseMessaging.instance.requestPermission(
        sound: sound,
        alert: alert,
        badge: badge,
      );
    } catch (e) {
      // Half two of the guard idiom: fail open and say why. A genuine
      // first-request failure is NOT swallowed silently — it is logged
      // here with its detail; user-facing surfaces stay quiet.
      debugPrint('==> push permission request skipped: $e');
      return null;
    } finally {
      _pending = null;
    }
  }
}
