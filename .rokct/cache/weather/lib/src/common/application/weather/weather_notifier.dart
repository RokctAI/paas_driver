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

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weather_sdk/src/common/application/weather/weather_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_service.dart';

/// Ported from pos main's `weather/service/weather_notifier.dart`.
/// Shop location and refresh cadence now come from [WeatherSdkConfig].
class WeatherNotifier extends StateNotifier<AsyncValue<WeatherState>> {
  final WeatherService _weatherService;
  Timer? _temperatureTimer;
  Timer? _refreshTimer;
  StreamSubscription? _connectivitySubscription;
  DateTime? _lastUpdate;
  static const Duration _temperatureDuration = Duration(seconds: 5);

  WeatherNotifier(this._weatherService) : super(const AsyncValue.loading()) {
    _loadWeather();
    _setupRefreshTimer();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _weatherService.connectivityStream.listen((
      isConnected,
    ) {
      if (isConnected && state.hasValue && state.value!.hasError) {
        refreshWeather();
      }
    });
  }

  void _setupRefreshTimer() {
    _refreshTimer?.cancel();
    debugLog(
      'Setting up weather refresh timer for '
      '${WeatherSdkConfig.refreshInterval.inMinutes} minutes',
    );
    _refreshTimer = Timer.periodic(WeatherSdkConfig.refreshInterval, (_) {
      debugLog('Weather refresh timer triggered');
      _loadWeather();
    });
  }

  void resetTemperatureTimer() {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(showTemperature: true));
      _startTemperatureTimer();
    }
  }

  Future<void> refreshWeather({bool isManual = false}) async {
    // Check if this is a manual refresh
    if (!isManual &&
        _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < const Duration(minutes: 30)) {
      debugLog('Skipping automatic refresh - last update was too recent');
      return;
    }

    try {
      final location = WeatherSdkConfig.resolveLocation();

      debugLog(
        'Refreshing weather for lat: ${location.latitude}, '
        'lon: ${location.longitude}',
      );

      final weatherData = await _weatherService.getCurrentWeather(
        location.latitude,
        location.longitude,
      );
      _lastUpdate = DateTime.now();

      state = AsyncValue.data(
        WeatherState(
          weatherData: weatherData,
          showTemperature: true,
          cityName: weatherData['location']['name'],
          hasError: false,
          lastUpdated: _lastUpdate,
        ),
      );

      _startTemperatureTimer();
    } catch (e, stack) {
      debugLog('Error refreshing weather: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _loadWeather() async {
    if (_lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < const Duration(minutes: 30)) {
      debugLog('Skipping weather load - last update was too recent');
      return;
    }

    try {
      final location = WeatherSdkConfig.resolveLocation();

      final weatherData = await _weatherService.getCurrentWeather(
        location.latitude,
        location.longitude,
      );
      _lastUpdate = DateTime.now();

      state = AsyncValue.data(
        WeatherState(
          weatherData: weatherData,
          showTemperature: true,
          cityName: weatherData['location']['name'],
          hasError: false,
          lastUpdated: _lastUpdate,
        ),
      );

      _startTemperatureTimer();
    } catch (e) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.data(
          state.value!.copyWith(
            version: DateTime.now().millisecondsSinceEpoch,
            hasError: true,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }
  }

  void _startTemperatureTimer() {
    _temperatureTimer?.cancel();
    _temperatureTimer = Timer(_temperatureDuration, () {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(showTemperature: false));
      }
    });
  }

  @override
  void dispose() {
    _temperatureTimer?.cancel();
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
