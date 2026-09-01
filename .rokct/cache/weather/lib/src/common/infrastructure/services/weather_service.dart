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
// The package:dio import below is only for its request/response types.
// The actual client comes from base_sdk's dioHttp (HttpService), which sets
// connectTimeout and receiveTimeout (30s) centrally on its BaseOptions; the
// injectable _client seam is test-only.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';

import 'package:weather_sdk/src/common/application/weather/weather_notifier.dart';
import 'package:weather_sdk/src/common/application/weather/weather_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';

/// Primary weather feed: shop lat/lng -> GeoNames reverse geocode ->
/// tenant Frappe proxy (weatherapi.com-shaped payload from the control
/// plane). Ported from pos main's `weather/service/weather_service.dart`;
/// the shop-location and constants seams now go through [WeatherSdkConfig].
///
/// Requests go through base_sdk's [HttpService] client so they ride the
/// standard interceptor chain — TimingInterceptor (timing telemetry) and the
/// ADR-006 trace-id stamping — instead of a bare package:http call that the
/// telemetry pipeline never sees. The tenant proxy fetch uses
/// `requireAuth: true` (TokenInterceptor stamps the bearer token); the
/// GeoNames reverse geocode stays `requireAuth: false` so the tenant bearer
/// token never reaches the third-party host.
class WeatherService {
  static const String geoNamesUrl = 'http://api.geonames.org/findNearbyJSON';

  /// Test seam only. Production resolves the shared [HttpService] client
  /// lazily so registration order at bootstrap does not matter.
  final Dio? _client;

  final _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;
  static const int maxRetries = 3;
  DateTime? _lastWeatherUpdate;

  WeatherService({Dio? client}) : _client = client {
    _initializeConnectivityMonitoring();
  }

  Dio _dio({required bool requireAuth}) =>
      _client ?? dioHttp.client(requireAuth: requireAuth);

  void _initializeConnectivityMonitoring() {
    AppConnectivity.connectivity().then((isConnected) {
      _connectivityController.add(isConnected);
    });

    // Check connectivity less frequently and only emit distinct values
    _connectivitySubscription = Stream.periodic(const Duration(minutes: 5))
        .asyncMap((_) => AppConnectivity.connectivity())
        .distinct()
        .listen((isConnected) {
      _connectivityController.add(isConnected);
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<bool> checkConnectivity() async {
    return AppConnectivity.connectivity();
  }

  Future<void> _handleConnectionRestored() async {
    try {
      // Check if we've updated recently
      if (_lastWeatherUpdate != null &&
          DateTime.now().difference(_lastWeatherUpdate!) <
              const Duration(minutes: 30)) {
        debugLog('Skipping connection restored update - too recent');
        return;
      }

      final location = WeatherSdkConfig.resolveLocation();
      await getCurrentWeather(location.latitude, location.longitude);
      _lastWeatherUpdate = DateTime.now();
    } catch (e) {
      debugLog('Error refreshing weather data after connection restored: $e');
    }
  }

  Future<String> _getCityFromCoordinates(double lat, double lon) async {
    // First, check if we have a cached city name
    final cachedCityName = await _getCachedCityName(lat, lon);
    if (cachedCityName != null) {
      return cachedCityName;
    }

    if (!await checkConnectivity()) {
      return 'messina,za'; // Default location if no connectivity
    }

    try {
      final response = await _dio(requireAuth: false).get<dynamic>(
        geoNamesUrl,
        queryParameters: {
          'lat': '$lat',
          'lng': '$lon',
          'username': WeatherSdkConfig.geoNamesUsername,
        },
      );

      final data = response.data;
      // Dio only auto-decodes application/json; fall back for providers that
      // serve JSON under another content type.
      final dynamic decoded = data is String ? json.decode(data) : data;
      if (decoded is Map<String, dynamic> &&
          decoded['geonames']?.isNotEmpty == true) {
        final cityData = decoded['geonames'][0];
        final cityName = cityData['name'];
        final countryCode = cityData['countryCode'].toString().toLowerCase();
        final fullCityName = '$cityName,$countryCode';

        // Cache the city name
        await _cacheCityName(lat, lon, fullCityName);
        return fullCityName;
      }
      return 'messina,za'; // Default location if API fails
    } catch (e) {
      debugLog('Error getting city name: $e');
      return 'messina,za'; // Default location on error
    }
  }

  Future<void> _cacheCityName(double lat, double lon, String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          'city_cache_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
      await prefs.setString(cacheKey, cityName);
    } catch (e) {
      debugLog('Error caching city name: $e');
    }
  }

  Future<String?> _getCachedCityName(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey =
          'city_cache_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
      return prefs.getString(cacheKey);
    } catch (e) {
      debugLog('Error getting cached city name: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    if (!await checkConnectivity()) {
      throw WeatherServiceException('No internet connection');
    }

    try {
      // Always get city name first (or use default)
      final cityLocation = await _getCityFromCoordinates(lat, lon);
      debugLog('Using location for weather: $cityLocation');

      final weatherData = await _fetchWithRetry(
        WeatherSdkConfig.weatherCmd,
        {'location': cityLocation},
      );

      _lastWeatherUpdate = DateTime.now();
      return weatherData;
    } catch (e) {
      debugLog('Weather fetch error: $e');
      throw WeatherServiceException('Failed to fetch weather data: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchWithRetry(
    String cmd,
    Map<String, String> payload, {
    int attempt = 1,
  }) async {
    try {
      // Every client-facing backend call POSTs the single universal
      // platform gateway ([kPlatformGatewayPath], imported from base_sdk)
      // with a `{"cmd": ..., "payload": ...}` envelope; [cmd] is the
      // weather manifest's whitelisted-method key minus the app segment
      // ([WeatherSdkConfig.weatherCmd]). The base client owns the tenant
      // base URL and (via TokenInterceptor) the bearer token. The raw
      // PlatformGateway class is not used here so the [_client] test seam
      // and this service's retry loop keep owning the transport.
      final response = await _dio(requireAuth: true).post<dynamic>(
        kPlatformGatewayPath,
        data: {'cmd': cmd, 'payload': payload},
      );

      final data = response.data;
      // Dio only auto-decodes application/json; fall back for providers that
      // serve JSON under another content type. A 204 arrives as null.
      final dynamic decoded = data is String ? json.decode(data) : data;
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded == null) return <String, dynamic>{};
      throw WeatherServiceException(
        'Unexpected response shape from weather API',
      );
    } on DioException catch (e) {
      if (attempt < maxRetries && await checkConnectivity()) {
        final waitTime = Duration(milliseconds: 1000 * attempt);
        await Future.delayed(waitTime);
        return _fetchWithRetry(cmd, payload, attempt: attempt + 1);
      }
      switch (e.response?.statusCode) {
        case 401:
          throw WeatherServiceException('Unauthorized - Invalid token');
        case 100:
          throw WeatherServiceException('not logged in');
        case 403:
          throw WeatherServiceException('Access forbidden');
        case 429:
          throw WeatherServiceException('Too many requests');
        default:
          throw WeatherServiceException(
            'Failed to load weather data: ${e.response?.statusCode}',
          );
      }
    } catch (e) {
      if (attempt < maxRetries && await checkConnectivity()) {
        final waitTime = Duration(milliseconds: 1000 * attempt);
        await Future.delayed(waitTime);
        return _fetchWithRetry(cmd, payload, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    // The shared [HttpService] client's lifecycle is owned by base_sdk, not
    // this service, so there is nothing else to release here.
  }
}

/// pos main used bare print(); keep the diagnostics but only in debug builds.
void debugLog(String message) {
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}

class WeatherServiceException implements Exception {
  final String message;
  final int? statusCode;

  WeatherServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'WeatherServiceException: $message';
}

// Providers
final weatherServiceProvider = Provider((ref) => WeatherService());

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherState>>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(weatherService);
});

final connectivityProvider = StreamProvider<bool>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.connectivityStream;
});
