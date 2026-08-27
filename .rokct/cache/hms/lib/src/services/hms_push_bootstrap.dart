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

import 'package:base_sdk/base_sdk.dart';
import 'package:flutter/foundation.dart';
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
class HmsPushBootstrap {
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

  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;
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
    try {
      // Subscribe BEFORE requesting the token so the async emission is
      // never missed. The stream also surfaces Push SDK error codes as
      // stream errors - swallow them fail-open.
      _tokenSubscription = Push.getTokenStream.listen(
        _onToken,
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

  void _onToken(String token) {
    if (token.isEmpty || token == _lastSyncedToken) {
      return;
    }
    _lastSyncedToken = token;
    unawaited(syncToken(token));
  }

  /// Registers [token] on the backend through the universal platform
  /// gateway - the exact call shape of the FCM token sync, with the
  /// provider marking it as an HMS token. Fail-open: an unauthenticated
  /// session (boot happens pre-login) or a network failure debugPrints and
  /// is retried naturally on the next app start.
  Future<void> syncToken(String token) async {
    try {
      await _gateway.tenant(registerDeviceTokenCmd, {
        'device_token': token,
        'provider': tokenProvider,
      });
    } catch (e) {
      debugPrint('==> HMS push token sync skipped: $e');
    }
  }

  /// Test seam: tears down the stream subscription and re-arms
  /// [initialize].
  @visibleForTesting
  Future<void> reset() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _lastSyncedToken = null;
    _initialized = false;
  }
}
