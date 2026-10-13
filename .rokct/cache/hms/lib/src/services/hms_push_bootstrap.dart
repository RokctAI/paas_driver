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

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:huawei_push/huawei_push.dart';

import 'package:hms_sdk/src/services/device_services.dart';

/// Huawei Push Kit bootstrap for GMS-free devices, owned by hms_sdk.
///
/// Wired into every composed main() via hms_sdk's manifest `boot_hooks`
/// (order 30, after comms_sdk's Firebase/FCM boot at order 10). It is a
/// strict no-op everywhere except an Android device that
/// [DeviceServices] proves is GMS-free AND HMS-capable - on GMS devices
/// (and on any detection error, which fails open to gms) comms_sdk's FCM
/// path stays the sole owner of push.
///
/// On the HMS path it turns Push Kit on, requests a push token, and syncs
/// the token to the backend through the SAME gateway method the FCM token
/// uses (`api.user.register_device_token` via base_sdk's
/// [PlatformGateway]), with `provider: 'hms'` so the server can tell the
/// token kinds apart - the backend stores `provider` verbatim on its
/// Device Token doc.
///
/// The token arrives asynchronously on Push Kit's token stream, so
/// [initialize] never blocks runApp on a network round-trip; every step is
/// fail-open (a failure debugPrints instead of blanking the app), matching
/// comms' firebase boot hook idiom.
class HmsPushBootstrap with WidgetsBindingObserver {
  HmsPushBootstrap._();

  static final HmsPushBootstrap instance = HmsPushBootstrap._();

  /// The one gateway method device tokens register through - the same cmd
  /// users_sdk's UserRepositoryImpl.updateFirebaseToken POSTs FCM tokens
  /// to (there with `provider: 'fcm'`).
  static const String registerDeviceTokenCmd = 'api.user.register_device_token';

  /// Sent as the `provider` field so HMS tokens are distinguishable from
  /// FCM ones server-side.
  static const String tokenProvider = 'hms';

  static const PlatformGateway _gateway = PlatformGateway();

  /// The [SessionStartHooks] id the re-sync after sign-in runs under.
  static const String sessionStartHookId = 'hms_push_token_sync';

  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;

  /// The newest token Push Kit handed out, synced or not.
  String? _latestToken;

  /// The token the backend last accepted. Only set on a successful call,
  /// so a sync that failed (boot runs before sign-in, as Guest) is retried.
  String? _lastSyncedToken;

  /// Idempotent, fail-open Push Kit boot. Safe to call on every platform;
  /// only the GMS-free + HMS-capable Android path does anything.
  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    if (_initialized) {
      return;
    }

    final availability = await DeviceServices.instance.resolve();
    if (availability != DeviceServicesAvailability.hms) {
      // gms (or fail-open) and neither: push stays with comms_sdk's FCM
      // path; nothing HMS-related may run.
      return;
    }

    _initialized = true;
    // Boot runs before sign-in, so the first sync usually fails as Guest.
    // auth_sdk fires SessionStartHooks once a sign-in has succeeded; send
    // the token again then, under the account that just signed in (the
    // backend moves a token to whoever registers it).
    SessionStartHooks.register(sessionStartHookId, onSessionStart);
    // And on the next foreground, for a token that is still unsynced (for
    // example one that arrived before the stored session was readable).
    WidgetsBinding.instance.addObserver(this);
    try {
      // Subscribe BEFORE requesting the token so the async emission is
      // never missed. The stream also surfaces Push SDK error codes as
      // stream errors - swallow them fail-open.
      _tokenSubscription = Push.getTokenStream.listen(
        handleToken,
        onError: (Object error) {
          debugPrint('==> HMS push token stream error: $error');
        },
      );
      await Push.turnOnPush();
      // Fire-and-forget by design: the token answers on getTokenStream.
      Push.getToken('');
    } catch (e) {
      debugPrint('==> HMS push init skipped: $e');
    }
  }

  /// A token from Push Kit's token stream. Public for tests only.
  @visibleForTesting
  void handleToken(String token) {
    if (token.isEmpty) {
      return;
    }
    _latestToken = token;
    if (token == _lastSyncedToken) {
      return;
    }
    unawaited(syncToken(token));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }
    final String? token = _latestToken;
    if (token == null || token.isEmpty || token == _lastSyncedToken) {
      return;
    }
    // Signed out (or an offline account) the call can only fail.
    final String session = LocalStorage.getToken();
    if (session.isEmpty || session.startsWith('offline:')) {
      return;
    }
    unawaited(syncToken(token));
  }

  /// What the [SessionStartHooks] entry runs. Public for tests only.
  @visibleForTesting
  Future<void> onSessionStart() async {
    final String? token = _latestToken;
    if (token == null || token.isEmpty) {
      return;
    }
    // Always re-sent: the same token may have been synced under the
    // account that was signed in before.
    await syncToken(token);
  }

  /// Registers [token] on the backend through the universal platform
  /// gateway - the exact call shape of the FCM token sync, with the
  /// provider marking it as an HMS token. Fail-open: an unauthenticated
  /// session (boot happens pre-login) or a network failure debugPrints and
  /// leaves the token unsynced; the next sign-in (SessionStartHooks) or the
  /// next app start sends it again. Returns whether the backend took it.
  Future<bool> syncToken(String token) async {
    try {
      final dynamic response = await _gateway.tenant(registerDeviceTokenCmd, {
        'device_token': token,
        'provider': tokenProvider,
      });
      // api_response can carry a refusal inside a 200 body.
      if (response is Map) {
        final int? code = int.tryParse('${response['status_code'] ?? ''}');
        if (code != null && code >= 400) {
          debugPrint('==> HMS push token sync refused: $code');
          return false;
        }
      }
      _lastSyncedToken = token;
      return true;
    } catch (e) {
      debugPrint('==> HMS push token sync skipped: $e');
      return false;
    }
  }

  /// Test seam: tears down the stream subscription and re-arms
  /// [initialize].
  @visibleForTesting
  Future<void> reset() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _latestToken = null;
    _lastSyncedToken = null;
    _initialized = false;
    SessionStartHooks.unregister(sessionStartHookId);
    WidgetsBinding.instance.removeObserver(this);
  }
}
