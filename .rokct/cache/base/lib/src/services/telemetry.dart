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


// compliance-ignore-file: flutter-http-timeout
// The package:dio import below is only for interceptor/exception types. The
// actual client comes from base_sdk's HttpService (dioHttp), which sets
// connectTimeout and receiveTimeout (30s) centrally on its BaseOptions; no
// unconfigured HTTP client is created in this file.

import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../handlers/http_service.dart';
import '../handlers/platform_gateway.dart';

/// telemetry_sdk's Dart client side (ADR-006 — previously zero files).
///
/// Lives in base_sdk per ADR-005: the shared kernel is the one home every
/// SDK may import, same as [TokenInterceptor]'s post-refork home. The
/// Frappe side (core/telemetry) already runs the generic error pipeline
/// (api_error_log doctype + log_frontend_error/forward_error_to_control);
/// this is the missing caller. telemetry/dart's telemetry_sdk package now
/// composes on top: it injects delivery policy through the
/// [TelemetryTransport] seam ([TelemetryClient.configure]) rather than
/// shipping a second client, and every other SDK extends the lane the
/// ADR-005 way — call [TelemetryClient.track]/[TelemetryClient.logError]
/// with their own events through the base_sdk import they already have.

/// One shared trace-id generator (ADR-006): the backend auto-populates
/// `trace_id` on any doctype carrying the field from the
/// X-Trace-ID/X-Request-ID header family. TokenInterceptor and any other
/// interceptor must use THIS, never hand-roll another format.
String generateTraceId() =>
    'mob-${DateTime.now().microsecondsSinceEpoch}-'
    '${math.Random().nextInt(0xFFFF).toRadixString(16)}';

/// Dio interceptor stamping every request with a trace id (kept if the
/// caller already set one).
class TraceIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('x-trace-id', generateTraceId);
    handler.next(options);
  }
}

/// Delivery override for [TelemetryClient] — the telemetry_sdk injection
/// seam (ADR-005/ADR-006). base_sdk owns the client because the shared
/// kernel is the one home every SDK may import; telemetry_sdk owns the
/// DELIVERY policy by injecting a transport through
/// [TelemetryClient.configure], and feature SDKs extend the lane with their
/// own events via [TelemetryClient.track] — never with a transport of their
/// own. The transport receives the gateway cmd ([TelemetryClient.cmd] or
/// [TelemetryClient.trackCmd]) and the exact `payload` map the default
/// gateway POST would carry; a transport that still wants the platform
/// gateway must POST `{cmd, payload}` to [kPlatformGatewayPath] itself.
typedef TelemetryTransport = Future<void> Function(
  String cmd,
  Map<String, dynamic> payload,
);

/// Minimal structured-event client for the existing
/// `log_frontend_error(error_message, context)` endpoint.
///
/// Contract: telemetry must never break the app — failures are swallowed
/// (logged locally), and every event debugPrints its full payload so debug
/// builds leave a usable trail even fully offline.
class TelemetryClient {
  TelemetryClient._();

  static final TelemetryClient I = TelemetryClient._();

  /// Gateway cmd (prefix-free) for the telemetry manifest's
  /// `tenant.api.log_frontend_error` whitelisted_methods mapping; delivery
  /// is a `POST` to [kPlatformGatewayPath] carrying this cmd.
  static const String cmd = 'tenant.api.log_frontend_error';

  /// The same error endpoint's key on a control-role site. The control-role
  /// gateway only resolves cmds carrying the verbatim `control:` prefix
  /// (see control hooks' whitelisted_methods), and an app connecting
  /// directly to control is planned — its errors must land locally at the
  /// site it points to (the control log_frontend_error twin), never in the
  /// tenant->control backend-error lane. [logError] falls back to this cmd
  /// when the unprefixed one fails, exactly like [track]'s
  /// [controlTrackCmd] fallback.
  static const String controlCmd = 'control:log_frontend_error';

  /// Gateway cmd (prefix-free) for the telemetry manifest's
  /// `tenant.api.track_event` whitelisted_methods mapping — the usage
  /// tracking lane. Same delivery door as [cmd]: a `POST` to
  /// [kPlatformGatewayPath] carrying this cmd.
  static const String trackCmd = 'tenant.api.track_event';

  /// The same tracking endpoint's key on a control-role site. The
  /// control-role gateway only resolves cmds carrying the verbatim
  /// `control:` prefix (see control hooks' whitelisted_methods), and apps
  /// can be pointed at any site role — an app connecting directly to
  /// control is planned — so [track] falls back to this cmd when the
  /// unprefixed one fails, exactly like TranslationSeeder's
  /// [TranslationSeeder.controlCmd] fallback.
  static const String controlTrackCmd = 'control:track_event';

  /// Injected delivery override (null = default gateway POST). Set only via
  /// [configure]; read only by [_deliver].
  static TelemetryTransport? _transport;

  /// telemetry_sdk's injection seam (ADR-005/ADR-006). Never calling this —
  /// today's every composed app without telemetry_sdk — leaves behavior
  /// identical to before the seam existed: [_deliver] falls through to the
  /// same HttpService gateway POST [logError] and [track] always made.
  /// telemetry_sdk's bootstrap is the formal owner of this call; passing
  /// null (the default) restores default delivery.
  static void configure({TelemetryTransport? transport}) {
    _transport = transport;
  }

  /// Single delivery door for both lanes: the injected [_transport] when
  /// configured, else the original gateway POST — a `POST` to
  /// [kPlatformGatewayPath] carrying `{cmd, payload}` through base_sdk's
  /// HttpService (per the platform rule, client HTTP always rides the
  /// gateway with a cmd). Callers own their try/catch: this may throw, and
  /// [logError]/[track] swallow per the never-break-the-app contract.
  ///
  /// Returns whether the event was handed to a transport at all: false
  /// only for the silent no-HttpService drop (uncomposed host, test
  /// harness), so [track] can report an honest delivery flag.
  Future<bool> _deliver(String cmd, Map<String, dynamic> payload) async {
    final transport = _transport;
    if (transport != null) {
      await transport(cmd, payload);
      return true;
    }
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<HttpService>()) return false;
    await getIt.get<HttpService>().client(requireAuth: true).post(
      kPlatformGatewayPath,
      data: {
        'cmd': cmd,
        'payload': payload,
      },
    );
    return true;
  }

  /// Fire-and-forget structured event: {type, context, session_id,
  /// timestamp}. [type] is a stable machine-readable class (snake_case);
  /// [context] carries whatever is needed to debug without reproducing.
  Future<void> logError({
    required String type,
    String? sessionId,
    Map<String, dynamic> context = const {},
  }) async {
    try {
      final payload = <String, dynamic>{
        'type': type,
        if (sessionId != null) 'session_id': sessionId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'context': context,
      };
      // Encode once, up front, INSIDE the try: a non-JSON-encodable value in
      // [context] must degrade to a stub event, never throw out of an
      // unawaited logError call.
      String encoded;
      try {
        encoded = jsonEncode(payload);
      } catch (e) {
        payload['context'] = {'encode_error': e.toString()};
        encoded = jsonEncode(payload);
      }
      // Local trail first — real even when the endpoint is unreachable.
      // Debug builds only: release logs must not carry full payloads.
      if (kDebugMode) debugPrint('==> telemetry $encoded');
      final body = {
        'error_message': type,
        'context': encoded,
      };
      try {
        await _deliver(cmd, body);
      } catch (_) {
        // The unprefixed cmd resolves only on tenant-role sites; a
        // control-role gateway rejects any cmd without the `control:`
        // prefix, and rejection shapes differ per role gateway — so
        // rather than pattern-matching the error, retry the send once
        // under the control-role key ([track]'s exact fallback). On a
        // tenant site a genuinely transient failure just costs one extra
        // attempt before the outer catch swallows it.
        await _deliver(controlCmd, body);
      }
    } catch (e) {
      debugPrint('==> telemetry delivery failed ($type): $e');
    }
  }

  /// Fire-and-forget usage event (the tracking lane, distinct from the
  /// error lane above). Wire contract (fixed — consumers code against it):
  /// gateway payload `{"event": <event>, "context": <JSON-encoded string of
  /// {"properties": {...}, "session_id": ..., "timestamp": ...}>}` under
  /// [trackCmd]. [event] is a stable machine-readable name (snake_case);
  /// [properties] carries optional structured detail.
  ///
  /// Same contract as [logError]: telemetry must never break the app —
  /// failures are swallowed (logged locally), and every event debugPrints
  /// its full payload so debug builds leave a usable trail even offline.
  ///
  /// Returns whether delivery completed without throwing (true) or was
  /// swallowed (false) — for callers with at-most-once bookkeeping such as
  /// AppUsageService's once-per-day `app_open` marker, which must not burn
  /// its daily slot on a failed send. Fire-and-forget callers keep
  /// ignoring the result (`unawaited(track(...))` stays valid).
  Future<bool> track(
    String event, {
    Map<String, dynamic>? properties,
    String? sessionId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'properties': properties ?? const <String, dynamic>{},
        'session_id': sessionId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      // Encode once, up front, INSIDE the try: a non-JSON-encodable value in
      // [properties] must degrade to a stub event, never throw out of an
      // unawaited track call.
      String encoded;
      try {
        encoded = jsonEncode(payload);
      } catch (e) {
        payload['properties'] = {'encode_error': e.toString()};
        encoded = jsonEncode(payload);
      }
      // Local trail first — real even when the endpoint is unreachable.
      // Debug builds only: release logs must not carry full payloads.
      if (kDebugMode) debugPrint('==> telemetry track $event $encoded');
      final body = {
        'event': event,
        'context': encoded,
      };
      try {
        return await _deliver(trackCmd, body);
      } catch (_) {
        // The unprefixed cmd resolves only on tenant-role sites; a
        // control-role gateway rejects any cmd without the `control:`
        // prefix, and rejection shapes differ per role gateway — so
        // rather than pattern-matching the error, retry the send once
        // under the control-role key (TranslationSeeder's exact
        // fallback). On a tenant site a genuinely transient failure just
        // costs one extra attempt before [track] reports undelivered.
        return await _deliver(controlTrackCmd, body);
      }
    } catch (e) {
      debugPrint('==> telemetry track delivery failed ($event): $e');
      return false;
    }
  }
}
