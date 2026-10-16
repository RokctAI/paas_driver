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

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// This device's push (FCM) token, read for a sign-out so the backend's
/// `api.user.logout` can delete the account's Device Token row for this
/// device and stop sending the old account's pushes here.
///
/// The ONE place a sign-out reads it: base_sdk's `ProfileNotifier.logOut`
/// and launch_sdk's `LauncherAuthControl.logOut` both call [forLogout], so
/// the two sign-outs cannot drift apart again (the launcher's used to send
/// `fcm: ''`, which left the row behind).
///
/// Never throws and never blocks a sign-out:
///   * firebase_messaging has no Windows/Linux/web implementation here, so
///     on those platforms getToken() throws `[core/no-app]`; the read is
///     skipped and the answer is '' (the comms firebase boot hook's guard);
///   * offline, or with Firebase not initialised, getToken() can throw or
///     wait on the network; any error, and anything slower than [timeout],
///     is '' too. Using the app offline is normal, so a sign-out made
///     offline still signs out (users_sdk's logoutAccount clears the local
///     session either way); it just cannot name the token to the server.
class DevicePushToken {
  DevicePushToken._();

  /// How long a sign-out waits for the token before going on without it.
  static const Duration timeout = Duration(seconds: 3);

  /// Test seam: replaces the platform guard and the FirebaseMessaging read.
  @visibleForTesting
  static Future<String?> Function()? readOverride;

  static bool get _platformHasFcm =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// The token, or '' where there is none to send.
  static Future<String> forLogout() async {
    final Future<String?> Function()? override = readOverride;
    if (override == null && !_platformHasFcm) return '';
    try {
      final String? token = await (override ?? _read)().timeout(timeout);
      return token ?? '';
    } catch (e) {
      debugPrint('==> logout fcm token skipped: $e');
      return '';
    }
  }

  static Future<String?> _read() => FirebaseMessaging.instance.getToken();
}
