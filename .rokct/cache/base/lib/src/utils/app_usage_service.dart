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


// lib/infrastructure/services/app_usage_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/telemetry.dart';

/// Days-in-app tracking over the platform telemetry lane.
///
/// The write side is a once-per-day `app_open` usage event through
/// [TelemetryClient.track] (gateway cmd `tenant.api.track_event`), guarded
/// by the `last_usage_recorded` SharedPreferences day-marker; the read side
/// is the telemetry package's `tenant.api.get_app_usage_stats` gateway
/// method, which counts the session user's distinct `app_open` days. Both
/// replace the retired legacy `/api/v1/rest/app-usage/record|stats` REST
/// endpoints (raw `package:http` + Bearer, bypassing the gateway; dead on
/// the platform backend and with zero record call sites).
class AppUsageService {
  /// Stats-map key for the current ISO week's usage figure, mirroring the
  /// backend's `days_in_app_this_year`. A backend-served value wins; when
  /// the stats payload lacks it, the value is filled from the local
  /// once-per-day counter kept by [recordAppOpenIfNeeded].
  static const String weekStatKey = 'days_in_app_this_week';

  /// Usage event sent at most once per day from the app-bootstrap path
  /// ([recordAppOpenIfNeeded]); the backend's stats method counts its
  /// distinct days.
  static const String appOpenEvent = 'app_open';

  /// Gateway cmd (prefix-free) for the telemetry manifest's
  /// `tenant.api.get_app_usage_stats` whitelisted_methods mapping — the
  /// stats read side of the `app_open` lane.
  static const String statsCmd = 'tenant.api.get_app_usage_stats';

  /// The same stats endpoint's key on a control-role site. The
  /// control-role gateway only resolves cmds carrying the verbatim
  /// `control:` prefix, and apps can be pointed at any site role (an app
  /// connecting directly to control is planned), so [getAppUsageStats]
  /// falls back to this cmd when the unprefixed one fails —
  /// TranslationSeeder's exact fallback shape. The control twin serves
  /// zeros when its usage table is absent, so the badge degrades
  /// gracefully instead of erroring.
  static const String controlStatsCmd = 'control:get_app_usage_stats';

  static const String _lastRecordedPref = 'last_usage_recorded';
  static const String _weekKeyPref = 'app_usage_week_key';
  static const String _weekCountPref = 'app_usage_days_this_week';

  /// ISO-8601 week id for [date]'s week, e.g. `2026-W35`. Keyed storage
  /// resets the local weekly counter automatically when the week rolls
  /// over — the same cheap SharedPreferences pattern `last_usage_recorded`
  /// already uses for the daily marker.
  static String isoWeekKey(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    // The ISO week's year/number are those of the week's Thursday.
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final dayOfYear =
        thursday.difference(DateTime(thursday.year, 1, 1)).inDays + 1;
    final week = ((dayOfYear - 1) ~/ 7) + 1;
    return '${thursday.year}-W$week';
  }

  // Counts today into the local weekly counter. Called exactly where the
  // once-per-day `last_usage_recorded` marker is set, so it increments at
  // most once per day and mirrors the server-side yearly figure's
  // "recorded days" semantics (offline days don't count for either).
  static Future<void> _markTodayInWeeklyCounter(
      SharedPreferences prefs) async {
    final weekKey = isoWeekKey(DateTime.now());
    final current =
        prefs.getString(_weekKeyPref) == weekKey
            ? (prefs.getInt(_weekCountPref) ?? 0)
            : 0;
    await prefs.setString(_weekKeyPref, weekKey);
    await prefs.setInt(_weekCountPref, current + 1);
  }

  // The local weekly counter, or 0 when the stored week id is not the
  // current week (stale counters never leak into a new week).
  static int _localWeeklyCount(SharedPreferences prefs) {
    if (prefs.getString(_weekKeyPref) != isoWeekKey(DateTime.now())) {
      return 0;
    }
    return prefs.getInt(_weekCountPref) ?? 0;
  }

  // Ensures [stats] carries [weekStatKey]: a backend-served value is kept,
  // otherwise the local counter fills the gap.
  static Future<Map<String, dynamic>> _withWeeklyStat(
      Map<String, dynamic> stats) async {
    if (stats[weekStatKey] != null) return stats;
    final prefs = await SharedPreferences.getInstance();
    return Map<String, dynamic>.of(stats)
      ..[weekStatKey] = _localWeeklyCount(prefs);
  }

  /// Platform label for the `app_open` properties. Deliberately not
  /// `dart:io` `Platform` (which throws on web): this runs on every
  /// composed app's bootstrap, desktop and web builds included.
  static String _platformLabel() {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  /// Sends the once-daily `app_open` usage event when today's slot is
  /// still open — the bootstrap trigger `BaseSdkDependencies.register`
  /// fires (fire-and-forget) on every cold start.
  ///
  /// At-most-once per day via the `last_usage_recorded` day-marker; the
  /// marker (and the local weekly counter) advance only when
  /// [TelemetryClient.track] reports delivery, so an offline launch does
  /// not burn the day's slot — the next launch retries. Never throws:
  /// usage tracking must never break bootstrap.
  static Future<void> recordAppOpenIfNeeded() async {
    try {
      // Auth-required, like the track lane itself: an anonymous launch
      // records nothing.
      if (LocalStorage.getToken().isEmpty) {
        debugPrint('AppUsageService: Not recording - user is not logged in');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      if (prefs.getString(_lastRecordedPref) == today) return;

      final packageInfo = await PackageInfo.fromPlatform();
      debugPrint('AppUsageService: Recording app open for today: $today');
      final delivered = await TelemetryClient.I.track(
        appOpenEvent,
        properties: {
          'platform': _platformLabel(),
          'app_version': packageInfo.version,
          'build_number': packageInfo.buildNumber,
        },
      );
      if (!delivered) return;

      await prefs.setString(_lastRecordedPref, today);
      await _markTodayInWeeklyCounter(prefs);
    } catch (e) {
      debugPrint('AppUsageService: Error recording app open: $e');
    }
  }

  /// Records today's `app_open` if still unsent, then returns the current
  /// stats — the pre-telemetry `record` semantics, kept for SDK backward
  /// compat. New callers on the bootstrap path use [recordAppOpenIfNeeded]
  /// (no stats round-trip).
  static Future<Map<String, dynamic>> recordAppUsage() async {
    if (LocalStorage.getToken().isEmpty) {
      debugPrint('AppUsageService: Not recording - user is not logged in');
      return {'days_in_app_this_year': 0, weekStatKey: 0};
    }
    await recordAppOpenIfNeeded();
    return await getAppUsageStats();
  }

  /// App usage statistics from the telemetry package's
  /// `tenant.api.get_app_usage_stats` gateway method, with the cached copy
  /// as the offline fallback. Response contract:
  /// `{"status": ..., "data": {"days_in_app_this_week": n,
  /// "days_in_app_this_year": n}}`.
  static Future<Map<String, dynamic>> getAppUsageStats() async {
    try {
      if (LocalStorage.getToken().isEmpty) {
        return {'days_in_app_this_year': 0, weekStatKey: 0}; // Not logged in
      }

      dynamic response;
      try {
        response = await const PlatformGateway().call(statsCmd);
      } catch (_) {
        // The unprefixed cmd resolves only on tenant-role sites; a
        // control-role gateway rejects any cmd without the `control:`
        // prefix, and rejection shapes differ per role gateway — so
        // rather than pattern-matching the error, retry once under the
        // control-role key (TranslationSeeder's exact fallback). A
        // failure of this retry too still lands in the outer catch and
        // answers from the cache.
        response = await const PlatformGateway().call(controlStatsCmd);
      }
      final data = response is Map ? response['data'] : null;
      final stats = data is Map
          ? Map<String, dynamic>.from(data)
          : {'days_in_app_this_year': 0};

      // Cache the stats
      await _cacheStats(stats);

      return await _withWeeklyStat(stats);
    } catch (e) {
      debugPrint('AppUsageService: Error getting app usage stats: $e');
      return await _getCachedStats();
    }
  }

  // Cache stats locally for offline use
  static Future<void> _cacheStats(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_usage_stats', jsonEncode(stats));
  }

  // Get cached stats when offline
  static Future<Map<String, dynamic>> _getCachedStats() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('app_usage_stats');

    if (cachedData != null) {
      try {
        return await _withWeeklyStat(
          Map<String, dynamic>.from(jsonDecode(cachedData)),
        );
      } catch (e) {
        return await _withWeeklyStat({'days_in_app_this_year': 0});
      }
    }

    return await _withWeeklyStat({'days_in_app_this_year': 0});
  }
}
