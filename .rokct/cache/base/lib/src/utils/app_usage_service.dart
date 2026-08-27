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


// lib/infrastructure/services/app_usage_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

class AppUsageService {
  /// Stats-map key for the current ISO week's usage figure, mirroring the
  /// backend's `days_in_app_this_year`. A backend-served value wins; when
  /// the stats payload lacks it, the value is filled from the local
  /// once-per-day counter kept by [recordAppUsage].
  static const String weekStatKey = 'days_in_app_this_week';

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

  static Future<Map<String, dynamic>> recordAppUsage() async {
    try {
      // Check if user is logged in
      final token = LocalStorage.getToken();
      if (token.isEmpty) {
        debugPrint('AppUsageService: Not recording - user is not logged in');
        return {'days_in_app_this_year': 0, weekStatKey: 0};
      }

      // Check if we already recorded today
      final prefs = await SharedPreferences.getInstance();
      final String? lastRecorded = prefs.getString('last_usage_recorded');
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Only record once per day
      if (lastRecorded != today) {
        // Get app version info
        final packageInfo = await PackageInfo.fromPlatform();
        final appVersion = packageInfo.version;
        final buildNumber = packageInfo.buildNumber;

        debugPrint('AppUsageService: Recording app usage for today: $today');
        final response = await http.post(
          Uri.parse('${AppConstants.baseUrl}/api/v1/rest/app-usage/record'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'platform': Platform.isAndroid ? 'Android' : 'iOS',
            'app_version': appVersion,
            'build_number': buildNumber,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          // Save that we've recorded today, and count today into the
          // local weekly counter (same once-per-day cadence).
          await prefs.setString('last_usage_recorded', today);
          await _markTodayInWeeklyCounter(prefs);
          final responseData = jsonDecode(response.body);

          // Cache the stats
          await _cacheStats(
            responseData['data'] ?? {'days_in_app_this_year': 0},
          );

          debugPrint(
            'AppUsageService: Successfully recorded - days in app: ${responseData['data']?['days_in_app_this_year']}',
          );
          return await _withWeeklyStat(
            responseData['data'] ?? {'days_in_app_this_year': 0},
          );
        } else {
          debugPrint(
            'AppUsageService: Failed to record - status code: ${response.statusCode}',
          );
          // Try to get cached stats if the request fails
          return await _getCachedStats();
        }
      } else {
        debugPrint('AppUsageService: Already recorded today, fetching stats');
        // If already recorded today, just get stats
        return await getAppUsageStats();
      }
    } catch (e) {
      debugPrint('AppUsageService: Error recording app usage: $e');
      return await _getCachedStats();
    }
  }

  // Get app usage statistics from API
  static Future<Map<String, dynamic>> getAppUsageStats() async {
    try {
      final token = LocalStorage.getToken();

      if (token.isEmpty) {
        return {'days_in_app_this_year': 0, weekStatKey: 0}; // Not logged in
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/rest/app-usage/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final stats = responseData['data'] ?? {'days_in_app_this_year': 0};

        // Cache the stats
        await _cacheStats(stats);

        return await _withWeeklyStat(stats);
      } else {
        return await _getCachedStats();
      }
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
