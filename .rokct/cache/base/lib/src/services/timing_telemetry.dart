// Copyright (c) 2026 RokctAI
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


// compliance-ignore-file: flutter-http-timeout
// The package:dio import below is only for the TimingInterceptor types wired
// into base_sdk's HttpService (dioHttp), which sets connectTimeout and
// receiveTimeout (30s) centrally on its BaseOptions; no unconfigured HTTP
// client is created in this file.

import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';

import 'telemetry.dart';

/// Timing telemetry (SDK audit item: the Dart layer shipped NO timing
/// signal — neither request durations nor frame/render stats — so
/// smoothness on real devices was assumed, never measured).
///
/// Two capture points, one delivery path:
///
///  * [TimingInterceptor] — Dio interceptor timing every request; wired
///    into [HttpService.client] alongside [TokenInterceptor].
///  * [SchedulerBinding.addTimingsCallback] — frame build/raster timings
///    (the audit's "check 7"), hooked lazily on the first timed request so
///    hosts need no extra wiring.
///
/// Everything aggregates in-memory and flushes as ONE summary event per
/// window through the existing [TelemetryClient] (apps never talk to
/// telemetry services directly — the backend pipeline is the only door).
/// Same contract as the rest of telemetry: this must never break the app,
/// so every hook swallows its own failures.
class TimingTelemetry {
  TimingTelemetry._();

  static final TimingTelemetry I = TimingTelemetry._();

  /// Event type sent through [TelemetryClient] — one per flushed window.
  static const String eventType = 'timing_report';

  /// Minimum stretch of wall time aggregated into one report.
  static const Duration flushInterval = Duration(minutes: 2);

  /// Frame-budget thresholds (audit: raster+UI < 16ms, 33ms/30fps floor).
  static const Duration _budget60 = Duration(milliseconds: 16);
  static const Duration _budget30 = Duration(milliseconds: 33);

  final Map<String, _RequestStats> _requests = {};
  int _frames = 0;
  int _framesOver16 = 0;
  int _framesOver33 = 0;
  int _buildMicros = 0;
  int _rasterMicros = 0;
  int _worstFrameMicros = 0;
  DateTime _windowStart = DateTime.now().toUtc();
  bool _frameHookInstalled = false;

  /// Installs the frame-timings hook once. Safe to call any time: it
  /// no-ops when already installed and swallows the "no binding yet"
  /// case (pure-Dart tests, pre-runApp calls).
  void ensureFrameTracking() {
    if (_frameHookInstalled) return;
    try {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
      _frameHookInstalled = true;
    } catch (_) {
      // No Flutter binding (tests / early startup) — try again next call.
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _frames++;
      _buildMicros += t.buildDuration.inMicroseconds;
      _rasterMicros += t.rasterDuration.inMicroseconds;
      final total = t.totalSpan;
      if (total.inMicroseconds > _worstFrameMicros) {
        _worstFrameMicros = total.inMicroseconds;
      }
      if (total > _budget30) {
        _framesOver33++;
        _framesOver16++;
      } else if (total > _budget60) {
        _framesOver16++;
      }
    }
    _maybeFlush();
  }

  /// Records one completed (or failed) request. [path] should be the URI
  /// path only — no query, no host — so stats aggregate per endpoint.
  /// Callers must not record telemetry delivery itself (see the cmd check
  /// in [TimingInterceptor]) — a slow flush must not feed back into the
  /// next report.
  void recordRequest(String path, Duration elapsed, {required bool ok}) {
    final stats = _requests.putIfAbsent(path, _RequestStats.new);
    stats.count++;
    if (!ok) stats.errors++;
    stats.totalMs += elapsed.inMilliseconds;
    if (elapsed.inMilliseconds > stats.maxMs) {
      stats.maxMs = elapsed.inMilliseconds;
    }
    _maybeFlush();
  }

  void _maybeFlush() {
    final now = DateTime.now().toUtc();
    if (now.difference(_windowStart) < flushInterval) return;
    if (_requests.isEmpty && _frames == 0) {
      _windowStart = now;
      return;
    }
    final payload = <String, dynamic>{
      'window_start': _windowStart.toIso8601String(),
      'window_end': now.toIso8601String(),
      if (_requests.isNotEmpty)
        'requests': {
          for (final e in _requests.entries) e.key: e.value.toJson(),
        },
      if (_frames > 0)
        'frames': {
          'count': _frames,
          'avg_build_ms': (_buildMicros / _frames / 1000).toStringAsFixed(2),
          'avg_raster_ms': (_rasterMicros / _frames / 1000).toStringAsFixed(2),
          'worst_ms': (_worstFrameMicros / 1000).toStringAsFixed(2),
          'over_16ms': _framesOver16,
          'over_33ms': _framesOver33,
        },
    };
    _requests.clear();
    _frames = 0;
    _framesOver16 = 0;
    _framesOver33 = 0;
    _buildMicros = 0;
    _rasterMicros = 0;
    _worstFrameMicros = 0;
    _windowStart = now;
    // Fire-and-forget; TelemetryClient already swallows delivery failures.
    TelemetryClient.I.logError(type: eventType, context: payload);
  }
}

class _RequestStats {
  int count = 0;
  int errors = 0;
  int totalMs = 0;
  int maxMs = 0;

  Map<String, dynamic> toJson() => {
        'count': count,
        'errors': errors,
        'total_ms': totalMs,
        'max_ms': maxMs,
      };
}

/// Dio interceptor timing every request into [TimingTelemetry]. Follows
/// [TraceIdInterceptor]/[TokenInterceptor]'s shape; wired by [HttpService]
/// so every SDK client is measured without per-feature work.
class TimingInterceptor extends Interceptor {
  static const _startKey = 'timing_telemetry_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    TimingTelemetry.I.ensureFrameTracking();
    // Monotonic clock: wall-clock (DateTime) differences go negative or
    // wildly wrong across NTP corrections / manual clock changes.
    options.extra[_startKey] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _record(response.requestOptions, ok: true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(err.requestOptions, ok: false);
    handler.next(err);
  }

  void _record(RequestOptions options, {required bool ok}) {
    try {
      final start = options.extra[_startKey];
      if (start is! Stopwatch) return;
      // Never time telemetry delivery itself — a slow flush must not feed
      // back into the next report. Delivery rides the shared gateway path,
      // so telemetry's own calls are identified by cmd, not by path.
      final dynamic data = options.data;
      if (data is Map && data['cmd'] == TelemetryClient.cmd) return;
      TimingTelemetry.I.recordRequest(
        options.uri.path,
        start.elapsed,
        ok: ok,
      );
    } catch (_) {
      // Telemetry must never break the request path.
    }
  }
}
