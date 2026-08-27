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

// compliance-ignore-file: flutter-http-timeout
// The package:dio import below is only for its request/response types.
// The actual client comes from base_sdk's dioHttp (HttpService), which sets
// connectTimeout and receiveTimeout (30s) centrally on its BaseOptions; the
// injectable _client seam is test-only.

import 'dart:async';
import 'dart:convert';

import 'package:base_sdk/src/di/injection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:weather_sdk/src/common/application/weather/open_weather_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_service.dart'
    show debugLog;

/// Extended (day 4-6) forecast, fetched directly from OpenWeatherMap with a
/// client-side key ([WeatherSdkConfig.openWeatherApiKey] - env default,
/// remote-config hydrated; never hardcoded). Ported from pos main's
/// `weather/service/open_weather_service.dart`.
///
/// Requests go through base_sdk's [HttpService] client so they ride the
/// standard interceptor chain — TimingInterceptor (timing telemetry) and the
/// ADR-006 trace-id stamping — instead of a bare package:http call that the
/// telemetry pipeline never sees. `requireAuth: false` keeps the tenant
/// bearer token off this third-party host.
class OpenWeatherService {
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Cache configuration
  static const Duration cacheDuration = Duration(minutes: 30);
  static const String cacheKey = 'open_weather_extended_cache';
  static const int maxRetries = 3;

  /// Test seam only. Production resolves the shared [HttpService] client
  /// lazily so registration order at bootstrap does not matter.
  final Dio? _client;

  OpenWeatherService({Dio? client}) : _client = client;

  Dio get _dio => _client ?? dioHttp.client(requireAuth: false);

  Future<Map<String, dynamic>> getExtendedForecast(
    double lat,
    double lon,
  ) async {
    try {
      // Check cache first
      final cachedData = await _getCachedData();
      if (cachedData != null && !_isCacheExpired(cachedData['timestamp'])) {
        debugLog('Using cached forecast data');
        return cachedData['data'];
      }

      final apiKey = WeatherSdkConfig.openWeatherApiKey;

      // Validate API key and coordinates
      if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY') {
        throw Exception('Invalid OpenWeatherMap API Key');
      }

      if (lat == 0 && lon == 0) {
        throw Exception('Invalid coordinates');
      }

      debugLog('Fetching extended forecast for coordinates: $lat, $lon');

      // Fetch fresh data with retry logic
      final data = await _fetchWithRetry('$baseUrl/forecast', {
        'appid': apiKey,
        'lat': lat.toString(),
        'lon': lon.toString(),
        'units': 'metric', // Ensure temperatures in Celsius
      });

      if (data['list'] == null || (data['list'] as List).isEmpty) {
        throw Exception('No forecast data available in the response');
      }

      debugLog('Received ${data['list'].length} forecast entries');

      // Cache the new data
      await _cacheData(data);

      return data;
    } catch (e, stack) {
      debugLog('Error fetching extended forecast: $e\n$stack');

      // If fetch fails and we have cached data, return it even if expired
      final cachedData = await _getCachedData();
      if (cachedData != null) {
        debugLog('Falling back to cached data');
        return cachedData['data'];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchWithRetry(
    String url,
    Map<String, String> queryParams, {
    int attempt = 1,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        url,
        queryParameters: queryParams,
      );

      final data = response.data;
      // Dio only auto-decodes application/json; fall back for providers that
      // serve JSON under another content type.
      final dynamic decoded = data is String ? json.decode(data) : data;
      if (decoded is! Map<String, dynamic>) {
        throw OpenWeatherServiceException(
          'Unexpected response shape from weather API',
        );
      }

      // Additional validation
      if (decoded['cod'] != '200') {
        throw Exception('API returned error: ${decoded['message']}');
      }

      return decoded;
    } on DioException catch (e) {
      debugLog('Fetch attempt $attempt failed: $e');
      if (attempt < maxRetries) {
        final waitTime = Duration(milliseconds: 1000 * attempt);
        await Future.delayed(waitTime);
        return _fetchWithRetry(url, queryParams, attempt: attempt + 1);
      }
      throw OpenWeatherServiceException(
        'Failed to load weather data: ${e.response?.statusCode}',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      debugLog('Fetch attempt $attempt failed: $e');
      if (attempt < maxRetries) {
        final waitTime = Duration(milliseconds: 1000 * attempt);
        await Future.delayed(waitTime);
        return _fetchWithRetry(url, queryParams, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _getCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
        return json.decode(cachedString);
      }
      return null;
    } catch (e) {
      debugLog('Error reading cache: $e');
      return null;
    }
  }

  Future<void> _cacheData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      debugLog('Error caching data: $e');
    }
  }

  bool _isCacheExpired(int timestamp) {
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age > cacheDuration.inMilliseconds;
  }

  void dispose() {
    // Nothing to release: the shared [HttpService] client's lifecycle is
    // owned by base_sdk, not this service.
  }
}

class OpenWeatherServiceException implements Exception {
  final String message;
  final int? statusCode;

  OpenWeatherServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'OpenWeatherServiceException: $message';
}

// Providers
final openWeatherServiceProvider = Provider((ref) => OpenWeatherService());

final openWeatherProvider =
    StateNotifierProvider<OpenWeatherNotifier, AsyncValue<OpenWeatherState>>((
  ref,
) {
  final weatherService = ref.watch(openWeatherServiceProvider);
  return OpenWeatherNotifier(weatherService);
});

class OpenWeatherNotifier extends StateNotifier<AsyncValue<OpenWeatherState>> {
  final OpenWeatherService _weatherService;

  OpenWeatherNotifier(this._weatherService) : super(const AsyncValue.loading());

  Future<void> loadExtendedForecast(double lat, double lon) async {
    try {
      state = const AsyncValue.loading();
      final weatherData = await _weatherService.getExtendedForecast(lat, lon);

      // Validate data before creating state
      if (weatherData['list'] == null ||
          (weatherData['list'] as List).isEmpty) {
        state = AsyncValue.error(
          Exception('No forecast data available'),
          StackTrace.current,
        );
        return;
      }

      state = AsyncValue.data(
        OpenWeatherState(weatherData: weatherData, lastUpdated: DateTime.now()),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      debugLog('Error loading extended forecast: $e');
    }
  }
}
