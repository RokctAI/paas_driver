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
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What one fleet app hands another so it opens signed in.
///
/// Either or both of:
///   * [code] - a one-time server code (`api.auth.handoff_mint`), redeemed
///     by the receiving app for its OWN session (`api.auth.handoff_redeem`);
///   * [account] - the sender's local account record, used when there is no
///     server to mint or redeem a code (a local-only account, or the backend
///     unreachable). It carries display fields, role and sync state only:
///     never a password, a password-vault entry or a token.
@immutable
class SessionHandoffPayload {
  const SessionHandoffPayload({this.code, this.account, this.sourcePackage});

  final String? code;
  final Map<String, dynamic>? account;

  /// The package that handed it over (set by the sending app's native side;
  /// trusted only because the channel is signature-guarded).
  final String? sourcePackage;

  bool get isEmpty =>
      (code == null || code!.isEmpty) && (account == null || account!.isEmpty);

  @override
  String toString() => 'SessionHandoffPayload(code: '
      '${code == null ? 'none' : 'present'}, account: '
      '${account == null ? 'none' : 'present'}, source: $sourcePackage)';
}

/// Shared sign-in between the fleet's own apps on one phone (Ray: "its one
/// device and same account so i expect them to use same token").
///
/// base_sdk owns the transport only: the Android channel
/// (`SessionHandoffBridge.kt`, registered by base_sdk's MainActivity) that
/// opens another same-key fleet app with a hand-off and takes one in.
/// WHAT is handed over and what is done with it belongs to auth_sdk, which
/// plugs in [payloadProvider] (sending) and reads [takePending] (receiving)
/// from its boot hook. Without auth_sdk both stay null and every call here
/// is a quiet no-op, so an app opens exactly as it always did.
///
/// Android only. Everywhere else, and in a shell whose MainActivity does
/// not register the channel yet, [open] answers false and [takePending]
/// answers null.
abstract class SessionHandoff {
  SessionHandoff._();

  static const String channelName = 'rokct.base_sdk/session_handoff';

  static MethodChannel _channel = const MethodChannel(channelName);

  /// Builds the hand-off for [targetPackage], or null for "open it the
  /// ordinary way" (signed out, nothing to hand over). Set by auth_sdk.
  static Future<SessionHandoffPayload?> Function(String targetPackage)?
      payloadProvider;

  /// How long [open] waits for [payloadProvider] before opening the app
  /// the ordinary way instead.
  static const Duration providerTimeout = Duration(seconds: 4);

  static final List<VoidCallback> _listeners = <VoidCallback>[];
  static bool _handlerSet = false;

  @visibleForTesting
  static set channelForTesting(MethodChannel channel) {
    _channel = channel;
    _handlerSet = false;
  }

  @visibleForTesting
  static void resetForTesting() {
    _channel = const MethodChannel(channelName);
    payloadProvider = null;
    _listeners.clear();
    _handlerSet = false;
  }

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Opens [packageName] carrying a hand-off when it is a fleet app signed
  /// with this app's key and there is something to hand over. Returns false
  /// whenever it did NOT open the app (not a fleet app, signed out, no
  /// channel, refused by the system), so the caller opens it the ordinary
  /// way. Never throws.
  static Future<bool> open(String packageName) async {
    final provider = payloadProvider;
    if (provider == null || packageName.isEmpty || !_supported) return false;
    try {
      final bool can = await _channel.invokeMethod<bool>(
            'canHandOff',
            <String, dynamic>{'package': packageName},
          ) ??
          false;
      if (!can) return false;
      final SessionHandoffPayload? payload =
          await provider(packageName).timeout(providerTimeout);
      if (payload == null || payload.isEmpty) return false;
      return await _channel.invokeMethod<bool>(
            'openWithHandoff',
            <String, dynamic>{
              'package': packageName,
              'code': payload.code,
              'account':
                  payload.account == null ? null : jsonEncode(payload.account),
            },
          ) ??
          false;
    } catch (e) {
      debugPrint('==> session handoff open skipped: ${e.runtimeType}');
      return false;
    }
  }

  /// The hand-off this app was opened with, once. Null when there is none
  /// (the common case), when it is older than two minutes, or when it was
  /// already taken. Never throws.
  static Future<SessionHandoffPayload?> takePending() async {
    if (!_supported) return null;
    try {
      final Map<dynamic, dynamic>? raw =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('takePending');
      return parse(raw);
    } catch (e) {
      debugPrint('==> session handoff read skipped: ${e.runtimeType}');
      return null;
    }
  }

  /// This app's own package name (the `client_id` a redeem reports), or
  /// null where it cannot be told.
  static Future<String?> ownPackage() async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<String>('ownPackage');
    } catch (_) {
      return null;
    }
  }

  /// Calls [listener] whenever a hand-off arrives while the app is running
  /// (the native side's `pendingChanged`). The listener then calls
  /// [takePending].
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
    if (_handlerSet || !_supported) return;
    _handlerSet = true;
    try {
      _channel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'pendingChanged') {
          for (final VoidCallback l in List<VoidCallback>.of(_listeners)) {
            l();
          }
        }
        return null;
      });
    } catch (_) {
      _handlerSet = false;
    }
  }

  /// The channel's map, as a payload. Null for anything unusable.
  @visibleForTesting
  static SessionHandoffPayload? parse(Map<dynamic, dynamic>? raw) {
    if (raw == null) return null;
    final String? code = raw['code'] is String ? raw['code'] as String : null;
    Map<String, dynamic>? account;
    final Object? accountRaw = raw['account'];
    if (accountRaw is String && accountRaw.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(accountRaw);
        if (decoded is Map) account = Map<String, dynamic>.from(decoded);
      } catch (_) {
        account = null;
      }
    }
    final payload = SessionHandoffPayload(
      code: (code == null || code.isEmpty) ? null : code,
      account: account,
      sourcePackage:
          raw['source'] is String ? raw['source'] as String : null,
    );
    return payload.isEmpty ? null : payload;
  }
}
