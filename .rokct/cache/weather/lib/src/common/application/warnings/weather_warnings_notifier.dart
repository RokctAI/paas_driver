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

import 'package:weather_sdk/src/common/application/warnings/weather_warnings_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_warnings_service.dart';

/// Owns the severe-weather warnings feed: loads on construction and
/// refreshes on the suite's shared cadence
/// ([WeatherSdkConfig.refreshInterval], same knob the weather feed uses).
///
/// Mirrors [WeatherNotifier]'s shape but holds a bare
/// [WeatherWarningsState] instead of an AsyncValue: this surface has no
/// loading or error UI by contract - until (and unless) real warnings
/// arrive, the state is [WeatherWarningsState.empty] and the banner renders
/// nothing. The service already swallows every failure into the empty
/// state; the try/catch here is belt-and-braces so no code path can ever
/// push an error into the UI.
class WeatherWarningsNotifier extends StateNotifier<WeatherWarningsState> {
  final WeatherWarningsService _service;
  Timer? _refreshTimer;
  DateTime? _lastUpdate;

  /// Collapse bursts of rebuild-triggered refreshes (same guard interval
  /// the weather feed uses).
  static const Duration _minRefreshGap = Duration(minutes: 30);

  WeatherWarningsNotifier(this._service) : super(WeatherWarningsState.empty) {
    _load();
    _refreshTimer = Timer.periodic(
      WeatherSdkConfig.refreshInterval,
      (_) => _load(force: true),
    );
  }

  /// Re-fetches warnings now (e.g. after the host learns a new shop
  /// location). Never throws.
  Future<void> refresh() => _load(force: true);

  Future<void> _load({bool force = false}) async {
    if (!force &&
        _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < _minRefreshGap) {
      return;
    }

    try {
      final location = WeatherSdkConfig.resolveLocation();
      final next = await _service.getWarnings(
        location.latitude,
        location.longitude,
      );
      _lastUpdate = DateTime.now();
      if (mounted) state = next;
    } catch (_) {
      // Silent by contract: any failure - even resolving the location -
      // means no banner, never an error surface.
      if (mounted) state = WeatherWarningsState.empty;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
