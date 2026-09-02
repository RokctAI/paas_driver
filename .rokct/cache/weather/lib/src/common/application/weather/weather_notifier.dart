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
