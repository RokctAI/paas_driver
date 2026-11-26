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

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:launch_sdk/launch_sdk.dart';
import 'package:weather_sdk/weather_sdk.dart';

/// Launcher-host weather wiring, installed by weather_sdk's manifest
/// `app_type.launcher` block to the same path as the generic template, so
/// launcher composes get this file and every other host keeps its own.
///
/// The launcher has no shop and may have no backend, so it brings its own
/// location (asked once, quietly) and its own feed ([LauncherWeatherService]:
/// the backend when signed in, MET Norway otherwise, the saved answer
/// offline). It fills launch_sdk's [LaunchWeatherSource] seam: today's
/// weather on the theme row, larger beside the closed Bible, and the
/// coming days on a tap (Ray, 2026-11-22). No location or no answer ever:
/// the spots stay empty, with no error.
class LauncherWeather extends ChangeNotifier
    with WidgetsBindingObserver
    implements LaunchWeatherSource {
  LauncherWeather({LauncherWeatherService? service})
      : _service = service ?? LauncherWeatherService();

  final LauncherWeatherService _service;
  Map<String, dynamic>? _data;
  WeatherLocation? _at;
  DateTime? _fetched;
  Timer? _timer;
  bool _busy = false;

  static const Duration refreshEvery = Duration(minutes: 30);

  @override
  Listenable get changes => this;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    _data = await _service.cached();
    if (_data != null) notifyListeners();
    await refresh();
    _timer = Timer.periodic(refreshEvery, (_) => refresh());
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    try {
      _at = await _service.locate() ?? _at;
      final WeatherLocation? at = _at;
      if (at == null) return;
      final Map<String, dynamic>? fresh = await _service.fetch(at);
      if (fresh != null) {
        _data = fresh;
        _fetched = DateTime.now();
        notifyListeners();
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final DateTime? last = _fetched;
    if (last == null || DateTime.now().difference(last) > refreshEvery) {
      refresh();
    }
  }

  @override
  Widget? compact(BuildContext context) =>
      LauncherWeatherViews.compact(context, _data);

  @override
  Widget? beside(BuildContext context) =>
      LauncherWeatherViews.beside(context, _data);

  @override
  List<LaunchWeatherDay> days(BuildContext context) => <LaunchWeatherDay>[
        for (final ({DateTime date, int code}) d
            in LauncherWeatherViews.forecastDays(_data))
          LaunchWeatherDay(
            date: d.date,
            icon: LauncherWeatherViews.dayIcon(context, d.code),
          ),
      ];

  @override
  Widget? hourly(BuildContext context, DateTime day) =>
      LauncherWeatherViews.hourly(context, _data, day);

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Boot hook: registers the launcher weather and starts it after the first
/// frame (the location ask needs a window).
void registerLauncherWeather() {
  final GetIt getIt = GetIt.instance;
  if (getIt.isRegistered<LaunchWeatherSource>()) return;
  final LauncherWeather weather = LauncherWeather();
  getIt.registerSingleton<LaunchWeatherSource>(weather);
  WidgetsBinding.instance.addPostFrameCallback((_) => weather.start());
}

/// Kept so anything importing this path (the generic header seam) still
/// compiles in launcher hosts.
void configureWeatherSdk() {}

class AppWeatherWidget extends StatelessWidget {
  final bool inlineExpansion;

  const AppWeatherWidget({super.key, this.inlineExpansion = true});

  @override
  Widget build(BuildContext context) =>
      WeatherWidget(inlineExpansion: inlineExpansion);
}
