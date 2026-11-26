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
import 'package:flutter/material.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:weather_sdk/src/common/infrastructure/services/launcher_weather_service.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_icon_mapper.dart';

/// The launcher's weather pieces (Ray, 2026-11-22, approved renders
/// weather_1..4): today's weather small on the theme row, larger beside
/// the closed Bible, and one row per coming day. All read the proxy
/// (weatherapi.com) shape that [LauncherWeatherService] returns.
///
/// Black and white like the rest of the launcher (Ray, 2026-11-22:
/// "Weather be black and white"): icons take the text colour of the theme.
abstract final class LauncherWeatherViews {
  static Color ink(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFFF2F2F2)
          : const Color(0xFF222222);

  static Color sub(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFFAAAAAA)
          : const Color(0xFF777777);

  static Map<String, dynamic>? _current(Map<String, dynamic> data) =>
      (data['current'] as Map?)?.cast<String, dynamic>();

  static List<Map<String, dynamic>> _days(Map<String, dynamic> data) =>
      (((data['forecast'] as Map?)?['forecastday'] as List?) ??
              const <dynamic>[])
          .whereType<Map>()
          .map((Map m) => m.cast<String, dynamic>())
          .toList();

  static int _code(Map<String, dynamic>? holder) =>
      ((holder?['condition'] as Map?)?['code'] as num?)?.toInt() ?? 1003;

  static String _deg(dynamic v) =>
      v is num ? '${v.round()}°' : '';

  static bool _night(Map<String, dynamic>? current) =>
      current?['is_day'] == 0;

  /// Today's weather for the theme row: icon and temperature.
  static Widget? compact(BuildContext context, Map<String, dynamic>? data) {
    final Map<String, dynamic>? current = data == null ? null : _current(data);
    if (current == null || current['temp_c'] is! num) return null;
    final int code = _code(current);
    return Semantics(
      label: '${_deg(current['temp_c'])} ${AppHelpers.getTranslation(LauncherWeatherService.conditionKey(code))}',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(WeatherIconMapper.getRemixIcon(code, isNight: _night(current)),
            size: 22, color: ink(context)),
        const SizedBox(width: 6),
        Text(_deg(current['temp_c']),
            style: TextStyle(
                fontSize: 16, color: ink(context), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  /// Today's weather beside the closed Bible: icon, temperature, its name,
  /// today's high and low.
  static Widget? beside(BuildContext context, Map<String, dynamic>? data) {
    final Map<String, dynamic>? current = data == null ? null : _current(data);
    if (current == null || current['temp_c'] is! num) return null;
    final int code = _code(current);
    final List<Map<String, dynamic>> days = _days(data!);
    final Map<String, dynamic>? today = days.isEmpty
        ? null
        : (days.first['day'] as Map?)?.cast<String, dynamic>();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(WeatherIconMapper.getRemixIcon(code, isNight: _night(current)),
            size: 40, color: ink(context)),
        const SizedBox(height: 4),
        Text(_deg(current['temp_c']),
            style: TextStyle(
                fontSize: 30, color: ink(context), fontWeight: FontWeight.w700)),
        Text(AppHelpers.getTranslation(LauncherWeatherService.conditionKey(code)),
            style: TextStyle(fontSize: 14, color: ink(context))),
        if (today != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
              '${AppHelpers.getTranslation('weather_high_short')} ${_deg(today['maxtemp_c'])}  '
              '${AppHelpers.getTranslation('weather_low_short')} ${_deg(today['mintemp_c'])}',
              style: TextStyle(fontSize: 12, color: sub(context))),
        ],
      ]),
    );
  }

  /// The forecast days, today first, as their date and condition code. The
  /// launcher's row names each day itself.
  static List<({DateTime date, int code})> forecastDays(
      Map<String, dynamic>? data) {
    if (data == null) return const <({DateTime date, int code})>[];
    return <({DateTime date, int code})>[
      for (final Map<String, dynamic> d in _days(data))
        if (DateTime.tryParse('${d['date']}') != null)
          (
            date: DateTime.parse('${d['date']}'),
            code: _code((d['day'] as Map?)?.cast<String, dynamic>()),
          ),
    ];
  }

  /// A day's icon, drawn the size of the theme row's icon.
  static Widget dayIcon(BuildContext context, int code) =>
      Icon(WeatherIconMapper.getRemixIcon(code), size: 22, color: ink(context));

  /// The hourly forecast of [day] for the long-press sheet: one row per
  /// hour. The feed carries hours for today only, so any other day, or a day
  /// without hours, gives null. MET Norway's data is CC BY 4.0, so its
  /// credit sits under the hours.
  static Widget? hourly(
      BuildContext context, Map<String, dynamic>? data, DateTime day) {
    if (data == null) return null;
    Map<String, dynamic>? match;
    for (final Map<String, dynamic> d in _days(data)) {
      final DateTime? date = DateTime.tryParse('${d['date']}');
      if (date != null &&
          date.year == day.year &&
          date.month == day.month &&
          date.day == day.day) {
        match = d;
        break;
      }
    }
    final List<Map<String, dynamic>> hours = <Map<String, dynamic>>[
      for (final Object? h in (match?['hour'] as List?) ?? const <Object?>[])
        if (h is Map) h.cast<String, dynamic>(),
    ];
    if (hours.isEmpty) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final Map<String, dynamic> h in hours) _hourRow(context, h),
        if (data['source'] == LauncherWeatherService.sourceMetNorway)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                AppHelpers.getTranslation('weather_source_met_norway'),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: sub(context))),
          ),
      ],
    );
  }

  static Widget _hourRow(BuildContext context, Map<String, dynamic> h) {
    final DateTime? time = DateTime.tryParse('${h['time']}');
    final String clock = time == null
        ? ''
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final num? precip = h['precip_mm'] as num?;
    final int code = _code(h);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: <Widget>[
        SizedBox(
          width: 48,
          child: Text(clock,
              style: TextStyle(fontSize: 14, color: sub(context))),
        ),
        Icon(WeatherIconMapper.getRemixIcon(code), size: 20, color: ink(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
              AppHelpers.getTranslation(LauncherWeatherService.conditionKey(code)),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: ink(context))),
        ),
        if (precip != null && precip > 0) ...<Widget>[
          Text('${precip.toStringAsFixed(1)} mm',
              style: TextStyle(fontSize: 12, color: sub(context))),
          const SizedBox(width: 10),
        ],
        Text(_deg(h['temp_c']),
            style: TextStyle(
                fontSize: 14, color: ink(context), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
