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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:weather_sdk/src/common/application/weather/weather_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_service.dart';
import 'package:weather_sdk/src/common/presentation/theme/weather_colors.dart';
import 'package:weather_sdk/src/common/presentation/widgets/rain_feedback_widget.dart';
import 'package:weather_sdk/src/common/presentation/widgets/temperature_badge.dart';
import 'package:weather_sdk/src/common/presentation/widgets/weather_forecast_dialog.dart';
import 'package:weather_sdk/src/common/presentation/widgets/weather_icon.dart';
import 'package:weather_sdk/src/common/presentation/widgets/weather_inline_forecast.dart';

/// Adaptive weather entry widget, per Ray: "minimal if in small screen but
/// interactive if in large screen. so no popups in small screens."
///
/// - LARGE screens ([WeatherSdkConfig.isLargeScreen]): pos main's full
///   header experience, byte-for-byte behavior - icon + temp/POP/UV badges +
///   cycling status text + city/rain-feedback, tap opens
///   [WeatherForecastDialog].
/// - SMALL screens: a minimal compact row (icon + temperature badge). Tap
///   toggles the popup-free [WeatherInlineForecast] card in flow below
///   (never a dialog). Hosts that embed this widget inside a fixed-height
///   header should pass [inlineExpansion] = false and place
///   [WeatherInlineForecast] in a scrollable body region themselves.
///
/// Ported from pos main's `weather/weather_widget.dart`; the large-screen
/// path is the original build, the small-screen path is new.
class WeatherWidget extends ConsumerStatefulWidget {
  /// Whether the small-screen tap expands the inline forecast right below
  /// this widget. Set false when the widget sits in a height-constrained
  /// header and expansion would overflow.
  final bool inlineExpansion;

  const WeatherWidget({super.key, this.inlineExpansion = true});

  @override
  ConsumerState<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends ConsumerState<WeatherWidget> {
  bool _expanded = false;

  Map<String, dynamic>? _getCurrentHourData(WeatherState state) {
    final todayForecast = state.forecast.isNotEmpty ? state.forecast[0] : null;
    if (todayForecast == null) {
      return null;
    }

    final now = DateTime.now();
    final hourlyData = todayForecast['hour'] as List<dynamic>;

    try {
      return hourlyData.firstWhere(
        (hour) => DateTime.parse(hour['time']).hour == now.hour,
      );
    } catch (e) {
      debugLog('Error getting current hour data: $e');
      return null;
    }
  }

  int? _getChanceOfRain(WeatherState state) {
    final currentHourData = _getCurrentHourData(state);
    return currentHourData?['chance_of_rain'] as int?;
  }

  String _cleanText(String text) {
    return text
        .replaceAll(' nearby', '')
        .replaceAll(' possible', '')
        .replaceAll('Patchy ', '');
  }

  Color _getUvBadgeColor(num uvIndex) {
    if (uvIndex >= 11) return AppStyle.red; // Extreme
    if (uvIndex >= 8) return WeatherColors.uvVeryHigh; // Very High
    if (uvIndex >= 6) return WeatherColors.uvHigh; // High (Yellow)
    if (uvIndex >= 3) return AppStyle.textDarkSecondary; // Moderate
    return AppStyle.textPrimary; // Low
  }

  num? _getUV(WeatherState state) {
    final currentHourData = _getCurrentHourData(state);
    return currentHourData?['uv'] as num?;
  }

  Widget _buildRetry(String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16.sp,
                    height: 16.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppStyle.cardDark,
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Text(
                    'Retrying...',
                    style: TextStyle(color: AppStyle.cardDark),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: AppStyle.textPrimary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          try {
            await ref.read(weatherProvider.notifier).refreshWeather();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Retry failed: ${e.toString()}',
                    style: TextStyle(color: AppStyle.white),
                  ),
                  backgroundColor: AppStyle.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppStyle.red,
                height: 1,
              ),
            ),
            SizedBox(width: 4.sp),
            Icon(Remix.refresh_line, size: 16.sp, color: AppStyle.red),
          ],
        ),
      ),
    );
  }

  /// pos main's full header row - the large-screen experience.
  Widget _buildLargeScreen(WeatherState weatherState) {
    final currentHourData = _getCurrentHourData(weatherState);
    if (currentHourData == null) {
      return _buildRetry('No weather data - Tap to retry');
    }

    final uv = _getUV(weatherState);
    final currentCondition = currentHourData['condition'];
    final chanceOfRain = _getChanceOfRain(weatherState);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) =>
                WeatherForecastDialog(weatherState: weatherState),
          );
        },
        child: Tooltip(
          message: !weatherState.showTemperature
              ? '${weatherState.cityName} Weather'
              : '',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Weather Icon and Status Section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 40.sp,
                        height: 40.sp,
                        child: WeatherIcon(
                          condition: currentCondition,
                          size: 40.sp,
                          color: AppStyle.textPrimary,
                          isNight: !weatherState.isDay,
                        ),
                      ),
                      if (weatherState.showTemperature)
                        Positioned(
                          left: 36.sp,
                          top: -4,
                          child: TemperatureBadge(
                            temperature: currentHourData['temp_c'].round(),
                            fontSize: 10,
                            backgroundColor: AppStyle.textPrimary.withOpacity(
                              0.8,
                            ),
                          ),
                        ),
                      if (!weatherState.showTemperature) ...[
                        if (currentHourData['will_it_rain'] == 1 &&
                            chanceOfRain != null &&
                            chanceOfRain >= WeatherSdkConfig.rainPop)
                          Positioned(
                            left: 36.sp,
                            top: -4,
                            child: TemperatureBadge(
                              temperature: chanceOfRain,
                              suffix: '%',
                              fontSize: 10,
                              backgroundColor: AppStyle.red,
                            ),
                          ),
                        if (uv != null &&
                            currentHourData['humidity'] != null &&
                            uv >= WeatherForecastDialog.minUV &&
                            currentHourData['humidity'] >=
                                WeatherForecastDialog.minHumidity)
                          Positioned(
                            left: 36.sp,
                            top: (chanceOfRain != null &&
                                    chanceOfRain >= WeatherSdkConfig.rainPop &&
                                    currentHourData['will_it_rain'] == 1)
                                ? 20
                                : -4,
                            child: TemperatureBadge(
                              temperature: uv.round(),
                              suffix: 'UV',
                              fontSize: 10,
                              backgroundColor: _getUvBadgeColor(uv),
                            ),
                          ),
                      ],
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 0.5.sp),
                    child: Text(
                      _cleanText(currentCondition['text']),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppStyle.textPrimary,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              // Weather Text/City Name Section
              Padding(
                padding: EdgeInsets.only(left: 8.sp),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: weatherState.showTemperature
                      ? Text(
                          weatherState.cityName,
                          key: const ValueKey('cityname'),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppStyle.textPrimary,
                            height: 1,
                          ),
                        )
                      : RainFeedbackWidget(
                          key: const ValueKey('feedback'),
                          weatherState: weatherState,
                          showCityName: false,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Minimal, popup-free small-screen rendering: icon + temperature badge;
  /// tap toggles the inline forecast card (when [WeatherWidget.inlineExpansion]).
  Widget _buildSmallScreen(WeatherState weatherState) {
    final currentHourData = _getCurrentHourData(weatherState);
    if (currentHourData == null) {
      return _buildRetry('No weather data');
    }

    final currentCondition = currentHourData['condition'];

    final compact = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.inlineExpansion
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: Tooltip(
          message: '${weatherState.cityName} Weather',
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 32.sp,
                height: 32.sp,
                child: WeatherIcon(
                  condition: currentCondition,
                  size: 32.sp,
                  color: AppStyle.textPrimary,
                  isNight: !weatherState.isDay,
                ),
              ),
              Positioned(
                left: 26.sp,
                top: -4,
                child: TemperatureBadge(
                  temperature: currentHourData['temp_c'].round(),
                  fontSize: 9,
                  backgroundColor: AppStyle.textPrimary.withOpacity(0.8),
                  showShadow: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.inlineExpansion) return compact;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        compact,
        if (_expanded)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: WeatherInlineForecast(weatherState: weatherState),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final isLarge = WeatherSdkConfig.isLargeScreen(context);

    return weatherAsync.when(
      data: (weatherState) => isLarge
          ? _buildLargeScreen(weatherState)
          : _buildSmallScreen(weatherState),
      loading: () => SizedBox(
        width: 24.sp,
        height: 24.sp,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppStyle.textPrimary),
      ),
      error: (error, stack) => _buildRetry(
        isLarge ? 'Failed to fetch weather - Tap to retry' : 'Weather offline',
      ),
    );
  }
}
