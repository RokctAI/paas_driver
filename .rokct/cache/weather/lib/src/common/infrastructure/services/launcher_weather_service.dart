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
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_service.dart';

/// Weather for a launcher home, with or without a Rokct backend (Ray,
/// 2026-11-22: "We need to solve weather if no backend available").
///
/// - Signed in to a backend: the tenant proxy feed, as every other host.
/// - No backend, or it fails: MET Norway's forecast, free (also for
///   commercial use, CC BY 4.0) with no key and no account. Only the
///   location goes out, rounded to two decimals (about a kilometre).
/// - Offline: the last answer saved on the phone.
/// - Nothing ever answered, or no location: null, and the launcher shows
///   an empty space with no error.
///
/// Both feeds come back in the proxy's weatherapi.com shape (current
/// temp_c/condition.code/is_day, forecast.forecastday[].day), so the
/// existing icon mapper serves both.
class LauncherWeatherService {
  LauncherWeatherService({Dio? dio, WeatherService? backend})
      : _dio = dio ?? Dio(),
        _backend = backend;

  final Dio _dio;
  final WeatherService? _backend;

  /// Prefix of the saved town per rounded point. Its own keys, so the weather
  /// SDK's city cache is left as it is.
  static const String townCachePrefix = 'launcher_town_';

  static const String cacheKey = 'weather_launcher_v2';
  static const String metNorwayUrl =
      'https://api.met.no/weatherapi/locationforecast/2.0/compact';

  /// A saved answer is reused, with no request, for this long at most.
  static const Duration reuseMaxAge = Duration(hours: 6);

  /// Identifies the app to MET Norway, as its terms ask. Names the app
  /// only; nothing about the user.
  static const String userAgent = 'RokctLauncher/1.0 (+https://rokct.ai)';

  /// The `source` value on a MET Norway answer; the views credit it.
  static const String sourceMetNorway = 'met-norway';

  /// Asks for the location once, quietly: a refusal, location off or no
  /// fix all answer null, with no message.
  Future<WeatherLocation?> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return WeatherLocation(
        latitude: round(position.latitude),
        longitude: round(position.longitude),
      );
    } catch (_) {
      return null;
    }
  }

  /// Two decimals: enough for the weather, not the house.
  static double round(double v) => (v * 100).roundToDouble() / 100;

  /// The last saved answer, or null.
  Future<Map<String, dynamic>?> cached() async => (await _saved())?.data;

  /// The town for [at] as `name,countrycode`, from the same GeoNames service
  /// the weather SDK uses, cached per rounded point. Null when GeoNames has no
  /// answer, so nothing is keyed on a guessed town.
  Future<String?> _town(WeatherLocation at) async {
    final String key =
        '$townCachePrefix${at.latitude.toStringAsFixed(2)}_${at.longitude.toStringAsFixed(2)}';
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString(key);
      if (cached != null) return cached;
      final Response<dynamic> res = await _dio.get<dynamic>(
        WeatherService.geoNamesUrl,
        queryParameters: <String, dynamic>{
          'lat': '${at.latitude}',
          'lng': '${at.longitude}',
          'username': WeatherSdkConfig.geoNamesUsername,
        },
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final dynamic body =
          res.data is String ? jsonDecode(res.data as String) : res.data;
      if (body is! Map || body['geonames'] is! List) return null;
      final List<dynamic> names = body['geonames'] as List<dynamic>;
      if (names.isEmpty) return null;
      final Map<dynamic, dynamic> place = names.first as Map<dynamic, dynamic>;
      final String town =
          '${place['name']},${'${place['countryCode']}'.toLowerCase()}';
      await prefs.setString(key, town);
      return town;
    } catch (_) {
      return null;
    }
  }

  Future<_SavedWeather?> _saved() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(cacheKey);
      if (raw == null) return null;
      return _SavedWeather.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// The local calendar day as yyyy-MM-dd.
  static String _dateKey(DateTime l) =>
      '${l.year.toString().padLeft(4, '0')}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';

  /// A fresh answer for [at]. The town of [at] comes from GeoNames, as the
  /// weather SDK already does for its backend, so everyone in a town shares
  /// one answer. The saved answer is reused, with no request, while it is
  /// for the same town, was fetched today (local date) and is under
  /// [reuseMaxAge] old. Without a town, nothing is reused. Otherwise a new
  /// answer is fetched and saved. When nothing answers, the saved one
  /// stands; null when there is neither.
  Future<Map<String, dynamic>?> fetch(WeatherLocation at,
      {DateTime Function()? now}) async {
    final DateTime clock = (now ?? DateTime.now)();
    final String? town = await _town(at);
    final _SavedWeather? saved = await _saved();
    if (town != null && saved != null && saved.reusableAt(town, clock)) {
      return saved.data;
    }

    Map<String, dynamic>? data;
    if (_signedIn()) {
      try {
        data = await (_backend ?? WeatherService())
            .getCurrentWeather(at.latitude, at.longitude);
        if (data['current'] == null) data = null;
      } catch (_) {
        data = null;
      }
    }
    if (data == null) {
      try {
        data = await metNorway(at);
      } catch (_) {
        data = null;
      }
    }
    if (data == null) return saved?.data;
    if (town != null) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          cacheKey,
          jsonEncode(_SavedWeather(clock.toUtc(), town, data).toJson()),
        );
      } catch (_) {}
    }
    return data;
  }

  bool _signedIn() {
    try {
      return LocalStorage.getToken().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// MET Norway's free forecast, mapped to the proxy's shape. Free for
  /// commercial use under CC BY 4.0; it asks for an identifying
  /// User-Agent (the app, never the user) and credit, which the days
  /// panel shows.
  Future<Map<String, dynamic>?> metNorway(WeatherLocation at) async {
    final Response<dynamic> res = await _dio.get<dynamic>(
      metNorwayUrl,
      queryParameters: <String, dynamic>{
        'lat': round(at.latitude),
        'lon': round(at.longitude),
      },
      options: Options(
        headers: <String, String>{'User-Agent': userAgent},
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    final dynamic body =
        res.data is String ? jsonDecode(res.data as String) : res.data;
    if (body is! Map) return null;
    return fromMetNorway(body.cast<String, dynamic>());
  }

  static num? _precip(Map<String, dynamic>? data) =>
      ((((data?['next_1_hours'] as Map?)?['details']) as Map?)?['precipitation_amount']) as num?;

  static String? _symbol(Map<String, dynamic>? data) {
    for (final String k in <String>['next_1_hours', 'next_6_hours', 'next_12_hours']) {
      final dynamic code = ((data?[k] as Map?)?['summary'] as Map?)?['symbol_code'];
      if (code is String) return code;
    }
    return null;
  }

  static num? _temp(Map<String, dynamic>? data) =>
      ((data?['instant'] as Map?)?['details'] as Map?)?['air_temperature'] as num?;

  /// Maps a MET Norway locationforecast answer to the proxy's
  /// weatherapi.com shape: now from the first hour, then one day per
  /// local date (high and low of its hours, its midday sky).
  static Map<String, dynamic>? fromMetNorway(Map<String, dynamic> body,
      {DateTime Function(DateTime utc)? toLocal}) {
    final List<dynamic> series =
        ((body['properties'] as Map?)?['timeseries'] as List?) ?? const <dynamic>[];
    if (series.isEmpty) return null;
    final DateTime Function(DateTime) local = toLocal ?? (DateTime t) => t.toLocal();
    // Hourly entries are kept for every day the feed carries them: the
    // hourly steps near-term, then 6-hourly further out.
    final Map<String, List<Map<String, dynamic>>> hoursByDate =
        <String, List<Map<String, dynamic>>>{};
    final Map<String, dynamic>? first =
        ((series.first as Map?)?['data'] as Map?)?.cast<String, dynamic>();
    final num? now = _temp(first);
    if (now == null) return null;
    final String nowSymbol = _symbol(first) ?? 'partlycloudy_day';

    final Map<String, List<num>> temps = <String, List<num>>{};
    final Map<String, String> sky = <String, String>{};
    final Map<String, int> skyDistance = <String, int>{};
    final List<String> order = <String>[];
    for (final dynamic e in series) {
      if (e is! Map) continue;
      final DateTime? t = DateTime.tryParse('${e['time']}');
      final Map<String, dynamic>? data = (e['data'] as Map?)?.cast<String, dynamic>();
      if (t == null || data == null) continue;
      final DateTime l = local(t.toUtc());
      final String date = _dateKey(l);
      if (!temps.containsKey(date)) {
        if (order.length == 7) break;
        order.add(date);
        temps[date] = <num>[];
      }
      final num? temp = _temp(data);
      if (temp != null) temps[date]!.add(temp);
      final String? symbol = _symbol(data);
      if (temp != null) {
        (hoursByDate[date] ??= <Map<String, dynamic>>[]).add(<String, dynamic>{
          'time': l.toIso8601String(),
          'temp_c': temp.toDouble(),
          'condition': <String, dynamic>{
            'code': weatherApiCodeForSymbol(symbol ?? 'partlycloudy_day'),
          },
          'precip_mm': _precip(data)?.toDouble() ?? 0.0,
        });
      }
      final int distance = (l.hour - 12).abs();
      if (symbol != null && distance < (skyDistance[date] ?? 99)) {
        sky[date] = symbol;
        skyDistance[date] = distance;
      }
    }
    return <String, dynamic>{
      'current': <String, dynamic>{
        'temp_c': now.toDouble(),
        'is_day': nowSymbol.endsWith('_night') ? 0 : 1,
        'condition': <String, dynamic>{'code': weatherApiCodeForSymbol(nowSymbol)},
      },
      'forecast': <String, dynamic>{
        'forecastday': <Map<String, dynamic>>[
          for (final String date in order)
            if (temps[date]!.isNotEmpty)
              <String, dynamic>{
                'date': date,
                'day': <String, dynamic>{
                  'maxtemp_c': temps[date]!.reduce((num a, num b) => a > b ? a : b).toDouble(),
                  'mintemp_c': temps[date]!.reduce((num a, num b) => a < b ? a : b).toDouble(),
                  'condition': <String, dynamic>{
                    'code': weatherApiCodeForSymbol(sky[date] ?? 'partlycloudy_day'),
                  },
                },
                if (hoursByDate[date] != null) 'hour': hoursByDate[date],
              },
        ],
      },
      'source': sourceMetNorway,
    };
  }

  /// One saved answer: when it was fetched (UTC), for which town, and the
/// data itself.
class _SavedWeather {
  const _SavedWeather(this.fetchedAt, this.town, this.data);

  final DateTime fetchedAt;
  final String town;
  final Map<String, dynamic> data;

  static _SavedWeather? fromJson(Map<String, dynamic> json) {
    final Object? at = json['fetchedAt'];
    final Object? town = json['town'];
    final Object? data = json['data'];
    if (at is! String || town is! String || data is! Map) return null;
    final DateTime? t = DateTime.tryParse(at);
    if (t == null) return null;
    return _SavedWeather(t.toUtc(), town, data.cast<String, dynamic>());
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fetchedAt': fetchedAt.toIso8601String(),
        'town': town,
        'data': data,
      };

  /// Reusable for [currentTown] at [clock]: the same town, fetched on the
  /// same local day, and not older than [LauncherWeatherService.reuseMaxAge].
  bool reusableAt(String currentTown, DateTime clock) {
    if (town != currentTown) return false;
    final Duration age = clock.toUtc().difference(fetchedAt);
    if (age.isNegative || age >= LauncherWeatherService.reuseMaxAge) return false;
    final DateTime fetchedLocal = fetchedAt.toLocal();
    final DateTime now = clock.toLocal();
    return fetchedLocal.year == now.year &&
        fetchedLocal.month == now.month &&
        fetchedLocal.day == now.day;
  }
}

/// MET Norway symbol code (e.g. "lightrainshowers_day") to the nearest
  /// weatherapi.com code.
  static int weatherApiCodeForSymbol(String symbol) {
    final String s = symbol.split('_').first;
    if (s.contains('thunder')) return 1276;
    switch (s) {
      case 'clearsky':
        return 1000;
      case 'fair':
      case 'partlycloudy':
        return 1003;
      case 'cloudy':
        return 1009;
      case 'fog':
        return 1135;
      case 'lightrain':
        return 1183;
      case 'rain':
        return 1189;
      case 'heavyrain':
        return 1195;
      case 'lightrainshowers':
        return 1240;
      case 'rainshowers':
        return 1243;
      case 'heavyrainshowers':
        return 1246;
      case 'lightsnow':
      case 'lightsleet':
        return 1213;
      case 'snow':
      case 'sleet':
        return 1219;
      case 'heavysnow':
      case 'heavysleet':
        return 1225;
    }
    if (s.contains('snowshowers') || s.contains('sleetshowers')) return 1255;
    return 1003;
  }

  /// The trkey for a weatherapi.com code's plain name.
  static String conditionKey(int code) {
    if (code == 1000) return 'weather_clear';
    if (code == 1003) return 'weather_partly_cloudy';
    if (code == 1006 || code == 1009) return 'weather_cloudy';
    if (code == 1030 || code == 1135 || code == 1147) return 'weather_fog';
    if (code >= 1150 && code <= 1171) return 'weather_drizzle';
    if (code >= 1240 && code <= 1252) return 'weather_showers';
    if (code >= 1180 && code <= 1201) return 'weather_rain';
    if (code == 1087 || code >= 1273) return 'weather_thunder';
    if (code == 1066 || code == 1114 || code == 1117 ||
        (code >= 1204 && code <= 1237) || code >= 1255) {
      return 'weather_snow';
    }
    return 'weather_cloudy';
  }
}
