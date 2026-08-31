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

import 'dart:convert';

import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/src/common/domain/interface/restore_credential_platform.dart';
import 'package:auth_sdk/src/common/infrastructure/repositories/restore_credential_repository.dart';
import 'package:auth_sdk/src/common/services/platform_support.dart';

/// Drives Android's Restore Credentials across the whole session
/// lifecycle, so a user who moves to a new device arrives already signed
/// in instead of at a login screen.
///
/// Google Play requires this of any app supporting sign-in, optional or
/// mandatory, from April 2027, and measures compliance by successful
/// restore key retrieval.
///
/// Four moments matter, and this class owns all four:
///
///   * [ensureRestoreKey] -- after a successful sign-in or registration,
///     and again on a later launch when a session already exists. A cached
///     flag keeps it from re-running on every single login.
///   * [attemptRestore] -- on first launch, and again from the
///     `BackupAgent`'s `onRestoreFinished()` once app data has landed.
///   * [clear] -- on sign-out and on account deletion. Restore keys
///     otherwise survive until uninstall, so failing to call this would
///     sign a departed user back in on their next device.
///
/// Every entry point is safe to call unconditionally: on a platform with
/// no restore-credential support (which is every platform but Android, and
/// Android too until core's channel is installed) they all no-op quietly.
/// Nothing here ever surfaces an error to the user -- a restore that does
/// not happen is invisible, and the ordinary sign-in screen is the
/// fallback.
class RestoreCredentialService {
  RestoreCredentialService({
    RestoreCredentialRepository? repository,
  }) : _repository = repository ?? const RestoreCredentialRepository();

  final RestoreCredentialRepository _repository;

  /// Cached "we already registered a restore key for this install" marker,
  /// so the create path costs nothing on the overwhelmingly common launch
  /// where there is nothing to do.
  @visibleForTesting
  static const String hasSyncedFlagKey = 'has_synced_restore_credential';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  /// Whether this install has already registered a restore key.
  static Future<bool> hasSyncedRestoreCredential() async {
    try {
      return (await _prefs).getBool(hasSyncedFlagKey) ?? false;
    } catch (e) {
      debugPrint('==> restore credential flag read failed: $e');
      return false;
    }
  }

  static Future<void> _setSynced(bool value) async {
    try {
      await (await _prefs).setBool(hasSyncedFlagKey, value);
    } catch (e) {
      debugPrint('==> restore credential flag write failed: $e');
    }
  }

  /// Register a restore key for the signed-in account, unless this install
  /// already has one.
  ///
  /// Call after every successful sign-in or registration, and once more on
  /// a launch that finds an existing session -- the second case is what
  /// covers users who were already signed in before this shipped, and it
  /// is why the flag rather than the login event is the real guard.
  ///
  /// [force] skips the cached flag, for the rare case where the key is
  /// known to be stale.
  Future<bool> ensureRestoreKey({bool force = false}) async {
    if (LocalStorage.getToken().isEmpty) return false;
    if (!force && await hasSyncedRestoreCredential()) return false;

    final platform = RestoreCredentialPlatform.instance;
    if (!await platform.isSupported()) return false;

    final optionsResult = await _repository.registrationOptions();
    final Map<String, dynamic>? options = optionsResult.whenOrNull(
      success: (data) => data,
    );
    if (options == null || options.isEmpty) return false;

    final requestJson = jsonEncode(options);

    String? registration;
    try {
      registration = await platform.createRestoreKey(requestJson);
    } on RestoreCredentialE2eeUnavailable catch (e) {
      // Documented and expected: the device has no backup configured, no
      // screen lock, or no end-to-end encryption. Retry with cloud backup
      // off, which still yields a key that survives a direct
      // device-to-device transfer -- just not a restore from the cloud.
      debugPrint('==> restore credential: retrying without cloud backup ($e)');
      try {
        registration = await platform.createRestoreKey(
          requestJson,
          isCloudBackupEnabled: false,
        );
      } catch (e) {
        debugPrint('==> restore credential create (local-only) failed: $e');
        return false;
      }
    } catch (e) {
      debugPrint('==> restore credential create failed: $e');
      return false;
    }

    if (registration == null || registration.isEmpty) return false;

    final Map<String, dynamic>? credential = _decode(registration);
    if (credential == null) return false;

    final verify = await _repository.registrationVerify(credential);
    final ok = verify.when(
      success: (_) => true,
      failure: (_, __) => false,
    );
    if (ok) await _setSynced(true);
    return ok;
  }

  /// Try to sign in from a restore key held by this device.
  ///
  /// Call on first launch, and again from the `BackupAgent`'s
  /// `onRestoreFinished()` -- Google is explicit that `onRestore()` is
  /// never invoked for this and only `onRestoreFinished()` is reliable
  /// across backup types. Calling both is deliberate: the first-launch
  /// attempt gets a user signed in without waiting for data restoration
  /// to finish, and the post-restore attempt covers the case where the
  /// key only became available afterwards.
  ///
  /// Returns true when a session was established. A false is ordinary --
  /// most launches have nothing to restore -- and must be silent.
  ///
  /// [userRepository], when supplied, is used to re-register the push
  /// token: notifications are NOT part of what gets restored, so the FCM
  /// token is new on the new device and the backend is still holding the
  /// old one until we send it.
  Future<bool> attemptRestore({
    UserRepositoryFacade? userRepository,
  }) async {
    if (LocalStorage.getToken().isNotEmpty) return false;

    final platform = RestoreCredentialPlatform.instance;
    if (!await platform.isSupported()) return false;

    final optionsResult = await _repository.assertionOptions();
    final Map<String, dynamic>? options = optionsResult.whenOrNull(
      success: (data) => data,
    );
    if (options == null || options.isEmpty) return false;

    String? assertion;
    try {
      assertion = await platform.getRestoreKey(jsonEncode(options));
    } catch (e) {
      debugPrint('==> restore credential get failed: $e');
      return false;
    }
    // Null is the normal answer on a device that was never restored onto.
    if (assertion == null || assertion.isEmpty) return false;

    final Map<String, dynamic>? credential = _decode(assertion);
    if (credential == null) return false;

    final result = await _repository.assertionVerify(credential);
    final data = result.whenOrNull(success: (d) => d);
    final token = data?.data?.accessToken ?? '';
    if (token.isEmpty) return false;

    await LocalStorage.setToken(token);
    await SecureStorage.setRefreshToken(data?.data?.refreshToken);
    await LocalStorage.setTokenExpiry(data?.data?.expiresAt);

    // The restore key survived the move; this install now owns it, so do
    // not re-register one on the next launch.
    await _setSynced(true);

    // Push tokens are explicitly NOT restored. Without this the user is
    // signed in but silently stops receiving notifications.
    if (userRepository != null) {
      await syncFcmToken(userRepository);
    }
    return true;
  }

  /// Forget the restore key, on this device and on the server.
  ///
  /// MUST run on sign-out and on account deletion. A restore key is only
  /// removed automatically by uninstall or a data clear, so without this
  /// the next device migration would restore a session the user believed
  /// they had ended.
  ///
  /// The platform delete is attempted even if the server call fails, and
  /// vice versa: a half-cleared state should still lose the local key,
  /// which is the half that can actually sign someone in.
  Future<void> clear({bool revokeOnServer = true}) async {
    await _setSynced(false);

    if (revokeOnServer && LocalStorage.getToken().isNotEmpty) {
      // Best effort, and deliberately before the local clear: it needs the
      // session token that sign-out is about to discard.
      await _repository.revoke();
    }

    try {
      await RestoreCredentialPlatform.instance.clearRestoreKey();
    } catch (e) {
      debugPrint('==> restore credential clear failed: $e');
    }
  }

  static Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (e) {
      debugPrint('==> restore credential payload was not valid JSON: $e');
      return null;
    }
  }
}
