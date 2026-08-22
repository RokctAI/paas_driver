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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:weather_sdk/src/common/application/weather/weather_state.dart';
import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/weather_service.dart';
import 'package:weather_sdk/src/common/presentation/widgets/extended_forecast_loader.dart';
import 'package:weather_sdk/src/common/presentation/widgets/temperature_badge.dart';
import 'package:weather_sdk/src/common/presentation/widgets/weather_icon.dart';
import 'package:weather_sdk/src/common/presentation/widgets/weather_summary.dart';

/// SMALL-SCREEN forecast surface: a flat inline card, no dialogs anywhere in
/// its flow (Ray: "minimal if in small screen ... no popups in small
/// screens"). New in the SDK - pos main only had the dialog. Shows the day
/// summary, a horizontally scrollable day strip (tap swaps the summary
/// inline, no drill-down navigation) and the extended-days expansion tile.
///
/// Intended to be placed in normal layout flow (below the compact header
/// widget, in a settings/summary column, etc.), where it can grow downward.
class WeatherInlineForecast extends ConsumerStatefulWidget {
  final WeatherState weatherState;

  const WeatherInlineForecast({super.key, required this.weatherState});

  @override
  ConsumerState<WeatherInlineForecast> createState() =>
      _WeatherInlineForecastState();
}

class _WeatherInlineForecastState extends ConsumerState<WeatherInlineForecast> {
  int _selectedDay = 0;

  String _cleanText(String text) {
    return text
        .replaceAll(' nearby', '')
        .replaceAll(' possible', '')
        .replaceAll('Patchy ', '');
  }

  Widget _buildDayChip(int index, Map<String, dynamic> forecast) {
    final date = DateTime.parse(forecast['date']);
    final day = forecast['day'];
    final condition = day['condition'];
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isSelected = index == _selectedDay;

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = index),
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppStyle.strokeDark : AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(8.r),
          border: isSelected
              ? Border.all(color: AppStyle.textPrimary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isToday ? 'Today' : DateFormat('EEE').format(date),
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: AppStyle.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            WeatherIcon(condition: condition, size: 28.sp),
            SizedBox(height: 4.h),
            TemperatureBadge(
              temperature: day['avgtemp_c'].round(),
              fontSize: 10,
              showShadow: false,
            ),
            if (day['daily_will_it_rain'] == 1 &&
                day['daily_chance_of_rain'] > WeatherSdkConfig.rainPop) ...[
              SizedBox(height: 4.h),
              TemperatureBadge(
                temperature: day['daily_chance_of_rain'],
                suffix: '%',
                fontSize: 10,
                backgroundColor: AppStyle.red,
                showShadow: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(weatherProvider);
    final state = weatherAsync.value ?? widget.weatherState;
    final forecastDays = state.forecast;
    final location = WeatherSdkConfig.resolveLocation();

    if (forecastDays.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.sp),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Remix.cloud_off_line,
                color: AppStyle.textPrimary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'No forecast data available',
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: AppStyle.textPrimary),
            ),
          ],
        ),
      );
    }

    final selected = _selectedDay < forecastDays.length ? _selectedDay : 0;
    final selectedForecast = forecastDays[selected] as Map<String, dynamic>;
    final condition = selectedForecast['day']['condition'];

    return Container(
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      padding: EdgeInsets.all(12.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                state.cityName,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.textPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _cleanText(condition['text'].toString()),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                forecastDays.length,
                (i) => _buildDayChip(i, forecastDays[i]),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          WeatherSummary(forecast: selectedForecast, weatherState: state),
          // Same popup-free expansion tile the dialog uses for days 4-6.
          ExtendedForecastLoader(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        ],
      ),
    );
  }
}
