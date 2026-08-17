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
/// this is the missing caller.

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
      final getIt = GetIt.instance;
      if (!getIt.isRegistered<HttpService>()) return;
      await getIt.get<HttpService>().client(requireAuth: true).post(
        kPlatformGatewayPath,
        data: {
          'cmd': cmd,
          'payload': {
            'error_message': type,
            'context': encoded,
          },
        },
      );
    } catch (e) {
      debugPrint('==> telemetry delivery failed ($type): $e');
    }
  }
}
