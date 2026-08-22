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

import 'package:base_sdk/src/database/app_database.dart';

import 'package:weather_sdk/src/common/application/warnings/weather_warnings_state.dart';

/// The last successfully fetched warnings payload for one location, plus
/// when it was fetched ([cachedAt] backs the banner's "as of HH:mm"
/// freshness marker when the cached copy is rendered offline).
class CachedWeatherWarnings {
  final List<SevereWeatherWarning> warnings;
  final String attribution;
  final DateTime? generatedAt;
  final DateTime cachedAt;

  const CachedWeatherWarnings({
    required this.warnings,
    required this.attribution,
    this.generatedAt,
    required this.cachedAt,
  });
}

/// Offline cache for the severe-weather warnings feed, one JSON document
/// per watch location in base_sdk's shared drift database ([AppDatabase]'s
/// generic KV document store - base_sdk's CustomerCartStore pattern; small
/// per-location documents need no dedicated drift table, per the
/// KeyValueTable contract).
///
/// Failure contract matches the rest of the warnings surface: every method
/// swallows every error. A cache that cannot be read means "no cached
/// data" and a cache that cannot be written changes nothing - the live
/// fetch result the caller already has always wins. No cache problem may
/// ever surface in the UI or break the banner's existing behavior.
class WeatherWarningsCache {
  const WeatherWarningsCache();

  /// KV box holding one document per location key.
  static const String boxName = 'weather_warnings';

  AppDatabase get _db => AppDatabase();

  /// Location key at 2-decimal precision (~1.1 km): stable for a stationary
  /// shop and comfortably finer than the backend's 0.25-degree warning grid,
  /// so small GPS jitter (e.g. a parked courier) still hits the same entry.
  static String keyFor(double lat, double lon) =>
      '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';

  /// Persists the given warnings as the location's cached payload,
  /// stamping now as the fetch time. Best-effort: errors are swallowed.
  Future<void> save(
    double lat,
    double lon,
    WeatherWarningsState state,
  ) async {
    try {
      await _db.putItem(boxName, keyFor(lat, lon), {
        'warnings': state.warnings.map((w) => w.toJson()).toList(),
        'attribution': state.attribution,
        'generated_at': state.generatedAt?.toUtc().toIso8601String(),
        'cached_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Best-effort by contract.
    }
  }

  /// Loads the cached payload for a location, or null when absent or
  /// unreadable. Items that no longer parse are dropped one by one (same
  /// tolerance as the network parse path).
  Future<CachedWeatherWarnings?> load(double lat, double lon) async {
    try {
      final doc = await _db.getItem(boxName, keyFor(lat, lon));
      if (doc == null) return null;

      final cachedAt = doc['cached_at'] is String
          ? DateTime.tryParse(doc['cached_at'] as String)
          : null;
      if (cachedAt == null) return null;

      final rawWarnings = doc['warnings'];
      if (rawWarnings is! List) return null;
      final warnings = <SevereWeatherWarning>[];
      for (final item in rawWarnings) {
        if (item is! Map<String, dynamic>) continue;
        final parsed = SevereWeatherWarning.tryParse(item);
        if (parsed != null) warnings.add(parsed);
      }

      final attribution = doc['attribution'];
      return CachedWeatherWarnings(
        warnings: warnings,
        attribution: attribution is String && attribution.trim().isNotEmpty
            ? attribution.trim()
            : WeatherWarningsState.defaultAttribution,
        generatedAt: doc['generated_at'] is String
            ? DateTime.tryParse(doc['generated_at'] as String)
            : null,
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null; // Unreadable cache = no cached data, never an error.
    }
  }

  /// Drops the cached payload for a location (a successful refresh that
  /// reported no active warnings invalidates the stale copy). Best-effort.
  Future<void> clear(double lat, double lon) async {
    try {
      await _db.deleteItem(boxName, keyFor(lat, lon));
    } catch (_) {
      // Best-effort by contract.
    }
  }
}
