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

import 'dart:async';

import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:auth_sdk/src/common/services/restore_credential_service.dart';

/// Boot-time driver for Android's Restore Credentials.
///
/// Installed into the composed app's `main()` by auth_sdk's manifest
/// `boot_hooks` entry (`RestoreCredentialGate.install();`), the same way
/// [PendingOtpGate] is. That placement is what makes the two launch-time
/// obligations actually happen without every app shell hand-wiring them:
///
///   * **No session yet** -- try to restore one. This is the "retrieve on
///     first launch" half of Google's guidance, and it is what Play
///     measures as a successful restore key retrieval. On the common
///     launch, where the device holds no restore key, it costs one quiet
///     failed lookup and nothing is shown to the user.
///   * **Session already exists** -- make sure the account has a restore
///     key. This is the "create it on a later launch if the user is
///     already signed in" half, and it is the only thing that covers users
///     who signed in before this feature shipped. A cached flag stops it
///     re-running once it has succeeded.
///
/// The other half of retrieval -- the `BackupAgent`'s
/// `onRestoreFinished()`, which fires once app data has actually landed --
/// belongs to the Android side in core. It re-enters through
/// [restoreAfterBackupRestored], so both entry points end up in the same
/// place. Google is explicit that `onRestore()` is never called for this
/// and only `onRestoreFinished()` is reliable.
///
/// Nothing here can fail loudly. A restore that does not happen is
/// indistinguishable from an ordinary cold start, and the sign-in screen
/// is always the fallback.
class RestoreCredentialGate {
  RestoreCredentialGate._();

  static bool _installed = false;

  @visibleForTesting
  static RestoreCredentialService service = RestoreCredentialService();

  @visibleForTesting
  static void resetForTest() {
    _installed = false;
    service = RestoreCredentialService();
  }

  /// Boot hook entry point. Safe to call more than once.
  static void install() {
    if (_installed) return;
    _installed = true;
    // Deliberately not awaited: boot must not block on network I/O. Any
    // session this establishes lands before the first authenticated screen
    // asks for data, and if it does not, the app simply shows sign-in.
    unawaited(_run());
  }

  static Future<void> _run() async {
    try {
      if (LocalStorage.getToken().isEmpty) {
        await service.attemptRestore(userRepository: _userRepository());
      } else {
        await service.ensureRestoreKey();
      }
    } catch (e) {
      debugPrint('==> restore credential gate skipped: $e');
    }
  }

  /// Re-entry point for the Android `BackupAgent`'s `onRestoreFinished()`.
  ///
  /// Separate from [install] because it fires on its own schedule -- app
  /// data restoration can complete well after boot, and on that path the
  /// restore key may only have become readable at that moment.
  static Future<bool> restoreAfterBackupRestored() async {
    try {
      return await service.attemptRestore(userRepository: _userRepository());
    } catch (e) {
      debugPrint('==> restore after backup restore skipped: $e');
      return false;
    }
  }

  /// Forget the restore key. Call on sign-out and on account deletion.
  ///
  /// Exposed here as well as on the service so an app shell has one
  /// obvious symbol to reach for, next to the one it already installs.
  static Future<void> clear() => service.clear();

  /// The push-token sink, when the host composed one. Optional: a restore
  /// still succeeds without it, the user just keeps the stale FCM
  /// registration until something else refreshes it.
  static UserRepositoryFacade? _userRepository() {
    try {
      if (GetIt.instance.isRegistered<UserRepositoryFacade>()) {
        return GetIt.instance<UserRepositoryFacade>();
      }
    } catch (e) {
      debugPrint('==> restore credential gate: no user repository ($e)');
    }
    return null;
  }
}
