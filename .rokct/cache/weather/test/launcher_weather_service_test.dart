import 'package:flutter_test/flutter_test.dart';
import 'package:weather_sdk/weather_sdk.dart';

void main() {
  test('rounds the location to two decimals', () {
    expect(LauncherWeatherService.round(-22.34567), -22.35);
    expect(LauncherWeatherService.round(30.04123), 30.04);
  });

  test('maps a MET Norway answer to the proxy shape', () {
    Map<String, dynamic> hour(String time, double t, String sym) => <String, dynamic>{
          'time': time,
          'data': <String, dynamic>{
            'instant': <String, dynamic>{'details': <String, dynamic>{'air_temperature': t}},
            'next_1_hours': <String, dynamic>{'summary': <String, dynamic>{'symbol_code': sym}},
          },
        };
    final Map<String, dynamic>? data = LauncherWeatherService.fromMetNorway(
      <String, dynamic>{
        'properties': <String, dynamic>{
          'timeseries': <dynamic>[
            hour('2026-11-23T08:00:00Z', 24.4, 'clearsky_day'),
            hour('2026-11-23T12:00:00Z', 29.1, 'fair_day'),
            hour('2026-11-24T03:00:00Z', 13.0, 'rain_night'),
            hour('2026-11-24T12:00:00Z', 22.0, 'lightrainshowers_day'),
          ],
        },
      },
      toLocal: (DateTime t) => t,
    );
    expect(data!['current']['temp_c'], 24.4);
    expect(data['current']['condition']['code'], 1000);
    expect(data['source'], LauncherWeatherService.sourceMetNorway);
    final List<dynamic> days = data['forecast']['forecastday'] as List<dynamic>;
    expect(days, hasLength(2));
    expect(days[0]['day']['maxtemp_c'], 29.1);
    expect(days[1]['day']['mintemp_c'], 13.0);
    expect(days[1]['day']['condition']['code'], 1240);
  });

  test('a night symbol marks night', () {
    expect(LauncherWeatherService.weatherApiCodeForSymbol('heavyrainandthunder'), 1276);
    expect(LauncherWeatherService.weatherApiCodeForSymbol('snowshowers_day'), 1255);
  });

  test('no current temperature answers null', () {
    expect(LauncherWeatherService.fromMetNorway(<String, dynamic>{}), isNull);
  });

  test('every code has a plain name key', () {
    expect(LauncherWeatherService.conditionKey(1000), 'weather_clear');
    expect(LauncherWeatherService.conditionKey(1189), 'weather_rain');
    expect(LauncherWeatherService.conditionKey(1243), 'weather_showers');
    expect(LauncherWeatherService.conditionKey(1276), 'weather_thunder');
    expect(LauncherWeatherService.conditionKey(1219), 'weather_snow');
  });
}
