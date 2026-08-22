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

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';

import 'package:weather_sdk/src/common/application/warnings/weather_warnings_notifier.dart';
import 'package:weather_sdk/src/common/application/warnings/weather_warnings_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_service.dart'
    show debugLog;
import 'package:weather_sdk/src/common/infrastructure/services/weather_warnings_cache.dart';

/// Severe-weather early-warning feed: shop lat/lng -> tenant Frappe
/// `get_weather_warnings` cmd (warnings computed server-side per watch
/// location; copy and attribution are rendered by the backend).
///
/// Same transport as [WeatherService]: every backend call POSTs base_sdk's
/// single universal platform gateway ([kPlatformGatewayPath]) with a
/// `{"cmd": ..., "payload": ...}` envelope - never a bare or per-method URL -
/// so requests ride the standard interceptor chain (TimingInterceptor and
/// the ADR-006 trace-id stamping) with the bearer token via TokenInterceptor.
/// Unlike the geocoded weather feed, the payload carries raw coordinates:
/// the backend grid-cell-maps them itself, so no third-party geocode hop
/// exists on the warnings path.
///
/// Failure contract (deliberate contrast with [WeatherService], which
/// throws so the header can show its retry affordance): this service NEVER
/// throws and never surfaces an error object. Any failure (offline, HTTP
/// error, cmd not deployed yet on an older shell, malformed payload) now
/// first tries the location's offline cache - the last successfully
/// fetched payload, filtered to notices still inside their validity window
/// and flagged `fromCache` so the banner can add its freshness marker.
/// When the cache has nothing usable (or itself errors), the result is
/// [WeatherWarningsState.empty], which the UI renders as nothing at all -
/// byte-identical to the pre-cache behavior. A missing warning must not
/// manufacture anxiety or UI noise; diagnostics for failures are the
/// backend's Error Log, not this client.
class WeatherWarningsService {
  /// Test seam only. Production resolves the shared [HttpService] client
  /// lazily so registration order at bootstrap does not matter.
  final Dio? _client;

  /// Per-location offline cache in base_sdk's shared drift database. Every
  /// cache interaction is best-effort: a broken cache degrades to exactly
  /// the pre-cache behavior (empty state), never to an error.
  final WeatherWarningsCache _cache;

  WeatherWarningsService({Dio? client, WeatherWarningsCache? cache})
      : _client = client,
        _cache = cache ?? const WeatherWarningsCache();

  static const int maxRetries = 3;

  /// Explicit per-request bounds so a hung gateway can never wedge the
  /// refresh loop (connect timeout is owned by the shared client's
  /// BaseOptions in base_sdk's HttpService).
  static const Duration sendTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);

  Dio _dio() => _client ?? dioHttp.client(requireAuth: true);

  /// Fetches active warnings for [lat]/[lon]. Always completes with a
  /// state - never an error. On no connectivity or a failed fetch it now
  /// falls back to the location's cached payload (still-valid notices only,
  /// flagged `fromCache` for the banner's freshness marker); when the cache
  /// has nothing usable either, the result is [WeatherWarningsState.empty],
  /// exactly as before the cache existed.
  Future<WeatherWarningsState> getWarnings(double lat, double lon) async {
    try {
      if (!await AppConnectivity.connectivity()) {
        return _cachedFallback(lat, lon);
      }
      final decoded = await _fetchWithRetry(
        WeatherSdkConfig.weatherWarningsCmd,
        {'latitude': lat, 'longitude': lon},
      );
      final state = _parse(decoded);
      await _reconcileCache(lat, lon, decoded, state);
      return state;
    } catch (e) {
      debugLog('Weather warnings fetch error (silent): $e');
      return _cachedFallback(lat, lon);
    }
  }

  /// Keeps the offline cache in step with a completed fetch. Only a
  /// response that actually carried a `warnings` list is authoritative:
  /// warnings present -> overwrite the cached payload; genuinely empty ->
  /// invalidate the stale copy (the hazard has passed). A response without
  /// the list (unexpected shape) leaves the cache untouched. Never throws.
  Future<void> _reconcileCache(
    double lat,
    double lon,
    Map<String, dynamic> decoded,
    WeatherWarningsState state,
  ) async {
    try {
      if (_unwrap(decoded)['warnings'] is! List) return;
      if (state.hasWarnings) {
        await _cache.save(lat, lon, state);
      } else {
        await _cache.clear(lat, lon);
      }
    } catch (e) {
      debugLog('Weather warnings cache write error (silent): $e');
    }
  }

  /// Serves the location's cached payload when the live fetch is
  /// unavailable. Respects each notice's validity window - expired notices
  /// (and notices without a `valid_until` bound, which could otherwise go
  /// stale forever) are never shown from cache. Any cache problem resolves
  /// to the empty state: exactly the pre-cache behavior.
  Future<WeatherWarningsState> _cachedFallback(double lat, double lon) async {
    try {
      final cached = await _cache.load(lat, lon);
      if (cached == null) return WeatherWarningsState.empty;

      final now = DateTime.now();
      final active =
          cached.warnings.where((w) => w.isActiveAt(now)).toList();
      if (active.isEmpty) return WeatherWarningsState.empty;

      _sortMostUrgentFirst(active);
      return WeatherWarningsState(
        warnings: List.unmodifiable(active),
        attribution: cached.attribution,
        generatedAt: cached.generatedAt,
        fromCache: true,
        cachedAt: cached.cachedAt,
      );
    } catch (e) {
      debugLog('Weather warnings cache read error (silent): $e');
      return WeatherWarningsState.empty;
    }
  }

  Future<Map<String, dynamic>> _fetchWithRetry(
    String cmd,
    Map<String, double> payload, {
    int attempt = 1,
  }) async {
    try {
      // Same envelope as WeatherService._fetchWithRetry: POST the single
      // universal platform gateway with `{"cmd": ..., "payload": ...}`;
      // [cmd] is the weather manifest's whitelisted-method key minus the
      // app segment ([WeatherSdkConfig.weatherWarningsCmd]).
      final response = await _dio().post<dynamic>(
        kPlatformGatewayPath,
        data: {'cmd': cmd, 'payload': payload},
        options: Options(
          sendTimeout: sendTimeout,
          receiveTimeout: receiveTimeout,
        ),
      );

      final data = response.data;
      // Dio only auto-decodes application/json; fall back for providers
      // that serve JSON under another content type. A 204 arrives as null.
      final dynamic decoded = data is String ? json.decode(data) : data;
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (e) {
      if (attempt < maxRetries && await AppConnectivity.connectivity()) {
        final waitTime = Duration(milliseconds: 1000 * attempt);
        await Future.delayed(waitTime);
        return _fetchWithRetry(cmd, payload, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  /// Parses the cmd response shape (see the severe-weather integration
  /// design, section 2.3):
  ///
  /// ```json
  /// {
  ///   "warnings": [{"id": ..., "event_class": ..., "severity": ...,
  ///                 "severity_label": ..., "headline": ..., "message": ...,
  ///                 "onset": ..., "valid_until": ..., "issued_at": ...}],
  ///   "attribution": "Weather data by Open-Meteo.com",
  ///   "generated_at": "..."
  /// }
  /// ```
  ///
  /// Tolerates the payload arriving under a frappe `message` wrapper.
  /// Unparseable items are dropped one by one; anything else unexpected
  /// yields the empty state.
  WeatherWarningsState _parse(Map<String, dynamic> decoded) {
    final body = _unwrap(decoded);

    final rawWarnings = body['warnings'];
    if (rawWarnings is! List) return WeatherWarningsState.empty;

    final warnings = <SevereWeatherWarning>[];
    for (final item in rawWarnings) {
      if (item is! Map<String, dynamic>) continue;
      final parsed = SevereWeatherWarning.tryParse(item);
      if (parsed != null) warnings.add(parsed);
    }
    if (warnings.isEmpty) return WeatherWarningsState.empty;

    _sortMostUrgentFirst(warnings);

    final attribution = body['attribution'];
    return WeatherWarningsState(
      warnings: List.unmodifiable(warnings),
      attribution: attribution is String && attribution.trim().isNotEmpty
          ? attribution.trim()
          : WeatherWarningsState.defaultAttribution,
      generatedAt: body['generated_at'] is String
          ? DateTime.tryParse(body['generated_at'] as String)
          : null,
    );
  }

  /// Peels the optional frappe `message` wrapper off a gateway response.
  Map<String, dynamic> _unwrap(Map<String, dynamic> decoded) {
    if (decoded['warnings'] is! List &&
        decoded['message'] is Map<String, dynamic>) {
      return decoded['message'] as Map<String, dynamic>;
    }
    return decoded;
  }

  /// Most urgent first: "warning" (act now) before "heads_up" before
  /// "advisory" (soft neighbor-propagation notice), then by onset so the
  /// soonest hazard leads. Shared by the live parse and the cached
  /// fallback so both paths order identically.
  static void _sortMostUrgentFirst(List<SevereWeatherWarning> warnings) {
    warnings.sort((a, b) {
      if (a.severityRank != b.severityRank) {
        return b.severityRank.compareTo(a.severityRank);
      }
      final aOnset = a.onset;
      final bOnset = b.onset;
      if (aOnset == null && bOnset == null) return 0;
      if (aOnset == null) return 1;
      if (bOnset == null) return -1;
      return aOnset.compareTo(bOnset);
    });
  }
}

// Providers (living in the service file, matching the suite's convention).
final weatherWarningsServiceProvider =
    Provider((ref) => WeatherWarningsService());

final weatherWarningsProvider =
    StateNotifierProvider<WeatherWarningsNotifier, WeatherWarningsState>((ref) {
  final service = ref.watch(weatherWarningsServiceProvider);
  return WeatherWarningsNotifier(service);
});
