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

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';

import 'package:weather_sdk/src/common/application/warnings/weather_warnings_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_service.dart'
    show debugLog;

/// Delivery receipts for severe-weather notices: "seen" when the banner
/// renders a notice, "opened" when the user taps to expand. Backends use
/// these to measure whether an early warning actually reached people
/// (acknowledgment tracking half of the disaster-management wave; the
/// endpoint ships separately and this client is safe in any merge order
/// with it).
///
/// Same transport as [WeatherWarningsService]: POST base_sdk's universal
/// platform gateway with a `{"cmd": ..., "payload": ...}` envelope, cmd
/// [WeatherSdkConfig.weatherNoticeAckCmd], payload
/// `{"warning_id": ..., "event": "seen"|"opened", "client_ts": <ISO-8601>}`.
///
/// Contract, stricter than the fetch path because this is pure telemetry:
/// - Fire-and-forget: callers get `void` back and the UI is NEVER blocked,
///   slowed, or notified - not on success, not on failure.
/// - Exactly one attempt per warning per event per app session: no retries,
///   and an in-session de-dupe set swallows repeat calls (rebuilds,
///   re-expands), so the same receipt is never sent twice.
/// - Any failure (offline, HTTP error, a composed backend that does not
///   expose the cmd yet) is swallowed silently; diagnostics stay in
///   debugLog only.
class WeatherNoticeAckService {
  /// Test seam only, mirroring [WeatherWarningsService].
  final Dio? _client;

  WeatherNoticeAckService({Dio? client}) : _client = client;

  /// Tight bounds: a receipt is worthless if it is slow, and it must never
  /// hold resources hostage.
  static const Duration sendTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// App-session de-dupe: `"<warning_id>|<event>"` entries. Static so every
  /// resolution of the service (riverpod, direct construction) shares one
  /// session's bookkeeping; cleared only by process restart, matching the
  /// "once per app session" contract.
  static final Set<String> _sentThisSession = <String>{};

  Dio _dio() => _client ?? dioHttp.client(requireAuth: true);

  /// Reports that [warning] was rendered to the user.
  void ackSeen(SevereWeatherWarning warning) => _ack(warning, 'seen');

  /// Reports that the user tapped/expanded the surface showing [warning].
  void ackOpened(SevereWeatherWarning warning) => _ack(warning, 'opened');

  void _ack(SevereWeatherWarning warning, String event) {
    // No id means nothing to acknowledge against server-side.
    if (warning.id.isEmpty) return;
    // De-dupe BEFORE any async gap so concurrent rebuilds cannot double-add;
    // the entry stays claimed even if the single attempt fails (one attempt
    // per event per session, by contract).
    if (!_sentThisSession.add('${warning.id}|$event')) return;
    unawaited(_send(warning.id, event));
  }

  Future<void> _send(String warningId, String event) async {
    try {
      await _dio().post<dynamic>(
        kPlatformGatewayPath,
        data: {
          'cmd': WeatherSdkConfig.weatherNoticeAckCmd,
          'payload': {
            'warning_id': warningId,
            'event': event,
            'client_ts': DateTime.now().toUtc().toIso8601String(),
          },
        },
        options: Options(
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
        ),
      );
    } catch (e) {
      debugLog('Weather notice ack "$event" error (silent): $e');
    }
  }
}

// Provider lives in the service file, matching the suite's convention.
final weatherNoticeAckServiceProvider =
    Provider((ref) => WeatherNoticeAckService());
