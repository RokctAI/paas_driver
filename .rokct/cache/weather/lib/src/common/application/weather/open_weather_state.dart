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

import 'package:weather_sdk/src/common/infrastructure/services/weather_service.dart'
    show debugLog;

/// State for the OpenWeatherMap extended (day 4-6) forecast.
/// Ported from pos main's `weather/service/open_weather_state.dart`
/// (dropped an unused `dart:convert` import).
class OpenWeatherState {
  final Map<String, dynamic> weatherData;
  final DateTime lastUpdated;

  OpenWeatherState({required this.weatherData, DateTime? lastUpdated})
      : lastUpdated = lastUpdated ?? DateTime.now();

  // Get only the additional days (skip first three days)
  List<Map<String, dynamic>> getAdditionalDaysData() {
    try {
      final List<dynamic> listData = weatherData['list'] ?? [];
      if (listData.isEmpty) return [];

      // Group by date
      final Map<String, List<dynamic>> dailyGroups = {};
      for (var item in listData) {
        final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        final dateKey = '${date.year}-${date.month}-${date.day}';

        dailyGroups.putIfAbsent(dateKey, () => []).add(item);
      }

      // Get entries and skip first 3 days
      final entries = dailyGroups.entries.toList();
      if (entries.length < 4) return [];

      final additionalDays = entries.skip(3).take(3).map((entry) {
        // Prefer midday data, but fallback to a reasonable alternative
        final dailyData = entry.value;

        // Try to find midday data first
        final middayData = dailyData.firstWhere((item) {
          final hour = DateTime.fromMillisecondsSinceEpoch(
            item['dt'] * 1000,
          ).hour;
          return hour >= 10 && hour <= 14;
        }, orElse: () => dailyData[dailyData.length ~/ 2]);

        // Ensure we have weather data
        final weatherData = middayData['weather'][0] ?? {};

        // Force day icon
        String icon = weatherData['icon']?.toString() ?? '01d';
        if (icon.endsWith('n')) {
          icon = icon.replaceFirst('n', 'd');
        }

        return {
          'date': DateTime.fromMillisecondsSinceEpoch(
            middayData['dt'] * 1000,
          ).toString(),
          'day': {
            'avgtemp_c': middayData['main']['temp'],
            'maxtemp_c': middayData['main']['temp_max'],
            'mintemp_c': middayData['main']['temp_min'],
            'condition': {
              'icon': icon,
              'text': weatherData['description'] ?? 'Unknown',
              'main': weatherData['main'] ?? 'Unknown',
            },
            'daily_chance_of_rain': (middayData['pop'] * 100).round(),
          },
        };
      }).toList();

      return additionalDays;
    } catch (e) {
      debugLog('Error in getAdditionalDaysData: $e');
      return [];
    }
  }

  // Create a new instance with updated fields
  OpenWeatherState copyWith({
    Map<String, dynamic>? weatherData,
    DateTime? lastUpdated,
  }) {
    return OpenWeatherState(
      weatherData: weatherData ?? this.weatherData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Check if the weather data is stale
  bool isStale([Duration threshold = const Duration(minutes: 30)]) {
    return DateTime.now().difference(lastUpdated) > threshold;
  }
}
