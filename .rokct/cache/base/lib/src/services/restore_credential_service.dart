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
import 'package:flutter/services.dart';

/// Outcome of a restore-credential call.
enum RestoreCredentialStatus {
  /// The operation completed. [RestoreCredentialResult.responseJson] holds
  /// the WebAuthn response for create and retrieve; it is null for clear.
  success,

  /// Restore Credentials cannot run here at all: a non-Android platform, an
  /// Android build below 9 (API 28), or an app shell whose MainActivity does
  /// not register the native channel yet. Never an error condition — callers
  /// should fall back to their normal sign-in path.
  unsupported,

  /// The device could run it but the credential provider would not: no
  /// credential provider configured, Play services too old, or the restore
  /// key could be created neither with nor without cloud backup.
  unavailable,

  /// Retrieval found no restore credential for this app. The expected result
  /// on a device that was never restored, and on a first install.
  noCredential,

  /// The user dismissed the system UI.
  cancelled,

  /// Anything else. [RestoreCredentialResult.message] carries the detail.
  error,
}

/// Result of a [RestoreCredentialService] call.
@immutable
class RestoreCredentialResult {
  const RestoreCredentialResult({
    required this.status,
    this.responseJson,
    this.message,
    this.cloudBackupEnabled,
  });

  final RestoreCredentialStatus status;

  /// WebAuthn response JSON. For [RestoreCredentialService.create] this is
  /// `CreateRestoreCredentialResponse.responseJson`; for
  /// [RestoreCredentialService.retrieve] it is
  /// `RestoreCredential.authenticationResponseJson`. Null otherwise. Pass it
  /// straight to the relying party without parsing it here.
  final String? responseJson;

  /// Human-readable detail for the non-success statuses. Diagnostics only —
  /// never surface it to a user and never branch on its text.
  final String? message;

  /// For [RestoreCredentialService.create]: whether the key that was
  /// actually created is backed up to the cloud. False means the platform
  /// reported end-to-end encryption unavailable and the call was retried
  /// local-only, so the key will not survive a move to a new device. Null
  /// for the other operations.
  final bool? cloudBackupEnabled;

  bool get isSuccess => status == RestoreCredentialStatus.success;

  @override
  String toString() =>
      'RestoreCredentialResult($status, cloudBackup=$cloudBackupEnabled'
      '${message == null ? '' : ', $message'})';
}

/// Platform plumbing for Android's Restore Credentials API (Zero-Tap
/// Sign-In), which Play requires from April 2027.
///
/// This is the transport only. base_sdk deliberately does not decide when a
/// restore key is created, retrieved or deleted, and does not talk to the
/// relying party: the auth SDK owns the flow and passes the WebAuthn JSON
/// through as opaque strings.
///
/// Every method is safe to call on every platform. On anything but Android,
/// on Android below 9, and on an app shell that has not taken the template's
/// MainActivity update, calls return [RestoreCredentialStatus.unsupported]
/// rather than throwing — an unguarded platform call would otherwise break
/// the Windows and other non-mobile targets.
///
/// Typical use from the auth SDK:
///
/// ```dart
/// final service = RestoreCredentialService();
/// if (await service.consumeRestoreSignal()) {
///   final result = await service.retrieve(
///     requestJson: await api.fetchAuthenticationOptions(),
///   );
///   if (result.isSuccess) {
///     await api.verifyRestoreAssertion(result.responseJson!);
///   }
/// }
/// ```
class RestoreCredentialService {
  RestoreCredentialService._();

  factory RestoreCredentialService() =>
      _instance ??= RestoreCredentialService._();
  static RestoreCredentialService? _instance;

  /// Same channel name as the Kotlin handler in the android template's
  /// MainActivity.
  static const MethodChannel channel = MethodChannel(
    'rokct.base_sdk/restore_credentials',
  );

  /// Whether Restore Credentials can run on this device.
  ///
  /// True only on Android 9+ with the native channel present. False is a
  /// normal answer, not a failure — treat it as "use the ordinary sign-in
  /// path".
  Future<bool> isSupported() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('==> restore credential isSupported failed: $e');
      return false;
    }
  }

  /// Create (or replace) this app's restore credential.
  ///
  /// [requestJson] is the relying party's
  /// `PublicKeyCredentialCreationOptionsJSON`, passed through untouched.
  ///
  /// [isCloudBackupEnabled] true (the recommended default) lets the restore
  /// key ride the user's end-to-end-encrypted Google backup, so it survives
  /// a move to a new device. When the platform reports E2EE unavailable —
  /// backup off, no screen lock, or no E2EE — the native side retries once
  /// with cloud backup off rather than failing, and the result's
  /// [RestoreCredentialResult.cloudBackupEnabled] reports which one stuck.
  Future<RestoreCredentialResult> create({
    required String requestJson,
    bool isCloudBackupEnabled = true,
  }) {
    return _invoke('create', <String, Object?>{
      'requestJson': requestJson,
      'isCloudBackupEnabled': isCloudBackupEnabled,
    });
  }

  /// Retrieve the restore credential.
  ///
  /// [requestJson] is the relying party's
  /// `PublicKeyCredentialRequestOptionsJSON`. Returns
  /// [RestoreCredentialStatus.noCredential] when there is nothing to
  /// retrieve, which is the ordinary outcome on a device that was never
  /// restored.
  Future<RestoreCredentialResult> retrieve({required String requestJson}) {
    return _invoke('retrieve', <String, Object?>{'requestJson': requestJson});
  }

  /// Delete this app's restore credential. Call on sign-out so the next
  /// device restore does not resurrect the session.
  Future<RestoreCredentialResult> clear() =>
      _invoke('clear', const <String, Object?>{});

  // ─── Thin shape matching auth_sdk's RestoreCredentialPlatform ───
  //
  // auth_sdk (rokctai/users) declares an abstract RestoreCredentialPlatform
  // with a no-op default and installs an implementation of it at startup.
  // base_sdk cannot import auth_sdk (ADR-005 allows only the other
  // direction), so the adapter has to live over there - but these three
  // methods carry exactly its signatures, which makes that adapter four
  // one-line delegations with no translation.
  //
  // NOTE for that adapter: nothing here ever throws
  // RestoreCredentialE2eeUnavailable. The isCloudBackupEnabled retry is
  // already done natively (see RestoreCredentialBridge.create), so the
  // caller-side retry in auth_sdk's RestoreCredentialService is unreachable
  // rather than wrong. Use [create] instead of [createRestoreKey] if you
  // want to know which setting actually stuck.

  /// Create a restore key and return the platform's registration response
  /// JSON, or null when it could not be created. Signature-compatible with
  /// `RestoreCredentialPlatform.createRestoreKey`.
  Future<String?> createRestoreKey(
    String requestJson, {
    bool isCloudBackupEnabled = true,
  }) async {
    final result = await create(
      requestJson: requestJson,
      isCloudBackupEnabled: isCloudBackupEnabled,
    );
    return result.isSuccess ? result.responseJson : null;
  }

  /// Retrieve the restore key and return its authentication response JSON,
  /// or null when this device holds none. Signature-compatible with
  /// `RestoreCredentialPlatform.getRestoreKey`.
  Future<String?> getRestoreKey(String requestJson) async {
    final result = await retrieve(requestJson: requestJson);
    return result.isSuccess ? result.responseJson : null;
  }

  /// Delete this app's restore key. Signature-compatible with
  /// `RestoreCredentialPlatform.clearRestoreKey`.
  Future<void> clearRestoreKey() => clear();

  /// Whether a system restore has completed since this was last called, and
  /// clears the signal.
  ///
  /// Android runs `BackupAgent.onRestoreFinished()` in a process with no
  /// Flutter engine, so it cannot call into Dart. The agent records a flag
  /// instead and this reads it once. Returns false everywhere the platform
  /// plumbing is absent.
  Future<bool> consumeRestoreSignal() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await channel.invokeMethod<bool>('consumeRestoreSignal') ?? false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('==> restore credential signal read failed: $e');
      return false;
    }
  }

  Future<RestoreCredentialResult> _invoke(
    String method,
    Map<String, Object?> arguments,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const RestoreCredentialResult(
        status: RestoreCredentialStatus.unsupported,
        message: 'Restore Credentials is an Android-only API.',
      );
    }
    try {
      final raw = await channel.invokeMapMethod<String, Object?>(
        method,
        arguments,
      );
      if (raw == null) {
        return const RestoreCredentialResult(
          status: RestoreCredentialStatus.error,
          message: 'Native side returned no result.',
        );
      }
      return RestoreCredentialResult(
        status: _statusFrom(raw['status'] as String?),
        responseJson: raw['responseJson'] as String?,
        message: raw['message'] as String?,
        cloudBackupEnabled: raw['cloudBackupEnabled'] as bool?,
      );
    } on MissingPluginException {
      return const RestoreCredentialResult(
        status: RestoreCredentialStatus.unsupported,
        message: 'This app shell does not register the restore credential '
            'channel yet.',
      );
    } catch (e) {
      return RestoreCredentialResult(
        status: RestoreCredentialStatus.error,
        message: e.toString(),
      );
    }
  }

  static RestoreCredentialStatus _statusFrom(String? name) {
    for (final status in RestoreCredentialStatus.values) {
      if (status.name == name) return status;
    }
    return RestoreCredentialStatus.error;
  }
}
