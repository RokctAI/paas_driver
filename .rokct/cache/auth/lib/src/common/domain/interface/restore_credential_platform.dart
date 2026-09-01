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

import 'package:flutter/foundation.dart';

/// The seam between auth_sdk's restore-credential flow and the Android
/// platform channel that actually talks to `androidx.credentials`.
///
/// The channel itself is NOT implemented here. It belongs to base_sdk in
/// the core repo, which owns the Kotlin half (the `androidx.credentials`
/// dependency, the method channel, and the `BackupAgent` whose
/// `onRestoreFinished()` triggers a retrieval). This file is only the
/// contract auth_sdk codes against, so that:
///
///   * this package compiles, analyses and tests on its own, with no
///     dependency on core's implementation existing yet, and
///   * there is exactly one channel in the workspace -- auth_sdk never
///     grows a competing one.
///
/// The default is [NoRestoreCredentialPlatform], which reports itself
/// unsupported and does nothing. Every platform other than Android keeps
/// that default forever, which is correct: Restore Credentials is an
/// Android feature. On Android, the composed app installs core's
/// implementation into [RestoreCredentialPlatform.instance] during
/// startup, before the first auth flow runs.
abstract class RestoreCredentialPlatform {
  const RestoreCredentialPlatform();

  /// The active implementation. Defaults to the no-op, so nothing in the
  /// auth flow has to null-check or platform-check before calling.
  static RestoreCredentialPlatform instance =
      const NoRestoreCredentialPlatform();

  /// Whether this build can actually hold a restore credential: Android 9
  /// or newer, Google Play services 24220000 or newer, and
  /// `androidx.credentials` 1.5.0 or newer. Everything else answers false
  /// and the whole feature stays dormant.
  Future<bool> isSupported();

  /// Create a restore key from a WebAuthn `PublicKeyCredentialCreationOptionsJSON`
  /// and return the `RegistrationResponseJSON` the platform produced.
  ///
  /// [isCloudBackupEnabled] defaults to true, which is what Google
  /// recommends: it lets the key ride a cloud backup as well as a direct
  /// device-to-device transfer. When the device has no backup configured,
  /// no screen lock, or no end-to-end encryption, the platform reports
  /// [RestoreCredentialE2eeUnavailable] and the caller retries with false
  /// -- see RestoreCredentialService, which does exactly that.
  Future<String?> createRestoreKey(
    String requestJson, {
    bool isCloudBackupEnabled = true,
  });

  /// Retrieve the restore key using a WebAuthn
  /// `PublicKeyCredentialRequestOptionsJSON`, returning the
  /// `AuthenticationResponseJSON`, or null when this device holds none
  /// (the ordinary case on a device that was never restored onto).
  Future<String?> getRestoreKey(String requestJson);

  /// Delete the restore key held by this app.
  ///
  /// Restore keys are otherwise removed only by uninstall or a data clear,
  /// so signing out or deleting an account MUST call this: without it the
  /// next device restore would silently sign a departed user back in.
  Future<void> clearRestoreKey();
}

/// Raised when a restore key could not be created with cloud backup on.
///
/// This is the Dart mirror of `androidx.credentials`'
/// `E2eeUnavailableException`. It is not a failure -- it is the documented
/// signal to retry the same request with `isCloudBackupEnabled: false`,
/// which yields a local-only key that still survives a direct
/// device-to-device transfer.
class RestoreCredentialE2eeUnavailable implements Exception {
  const RestoreCredentialE2eeUnavailable([this.message]);

  final String? message;

  @override
  String toString() =>
      'RestoreCredentialE2eeUnavailable(${message ?? 'cloud backup unavailable'})';
}

/// The default implementation: this platform cannot hold restore keys.
///
/// Used on iOS, web and desktop permanently, on Android until core's
/// channel is installed, and throughout this package's own tests.
class NoRestoreCredentialPlatform extends RestoreCredentialPlatform {
  const NoRestoreCredentialPlatform();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<String?> createRestoreKey(
    String requestJson, {
    bool isCloudBackupEnabled = true,
  }) async {
    debugPrint('==> restore credential: create skipped (no platform)');
    return null;
  }

  @override
  Future<String?> getRestoreKey(String requestJson) async {
    debugPrint('==> restore credential: get skipped (no platform)');
    return null;
  }

  @override
  Future<void> clearRestoreKey() async {
    debugPrint('==> restore credential: clear skipped (no platform)');
  }
}
