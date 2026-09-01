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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:weather_sdk/src/common/config/weather_sdk_config.dart';
import 'package:weather_sdk/src/common/infrastructure/services/open_weather_icon_mapper.dart';
import 'package:weather_sdk/src/common/infrastructure/services/open_weather_service.dart';
import 'package:weather_sdk/src/common/presentation/widgets/temperature_badge.dart';

/// Horizontally scrollable day-4-6 cards from the OpenWeather feed.
/// Ported from pos main's `weather/extended_forecast_view.dart`.
class ExtendedForecastView extends ConsumerWidget {
  const ExtendedForecastView({super.key});

  Widget _buildForecastCard({
    required DateTime date,
    required double temperature,
    required Map<String, dynamic> condition,
    required int rainChance,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60.sp,
                height: 60.sp,
                decoration: BoxDecoration(
                  color: AppStyle.cardDarkAlt,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: WeatherSdkConfig.useNetworkIcons
                    ? Image.network(
                        OpenWeatherIconMapper.getIconUrl(condition['icon']),
                        width: 60.sp,
                        height: 60.sp,
                      )
                    : Icon(
                        OpenWeatherIconMapper.getRemixIcon(condition['icon']),
                        size: 60.sp,
                        color: AppStyle.textPrimary,
                      ),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: TemperatureBadge(
                  temperature: temperature.round(),
                  fontSize: 12,
                ),
              ),
              if (rainChance > WeatherSdkConfig.rainPop)
                Positioned(
                  right: -4,
                  top: 20,
                  child: TemperatureBadge(
                    temperature: rainChance,
                    suffix: '%',
                    fontSize: 12,
                    backgroundColor: AppStyle.red,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            DateFormat('EEEE').format(date),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: AppStyle.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            condition['description'].toString().capitalize(),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              letterSpacing: -0.3,
              color: AppStyle.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openWeatherAsync = ref.watch(openWeatherProvider);

    return openWeatherAsync.when(
      data: (state) {
        final additionalDays = state.getAdditionalDaysData();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Divider(color: AppStyle.strokeDark, height: 1),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: additionalDays.map((forecast) {
                    final day = forecast['day'];
                    final condition = day['condition'];
                    final date = DateTime.parse(forecast['date']);

                    return _buildForecastCard(
                      date: date,
                      temperature: day['avgtemp_c'],
                      condition: condition,
                      rainChance: day['daily_chance_of_rain'],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.all(24.sp),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppStyle.textPrimary),
          ),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: EdgeInsets.all(24.sp),
        child: Center(
          child: Text(
            'Failed to load extended forecast',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Renamed from pos's `StringExtension` so the barrel can export this file
/// alongside weather_forecast_dialog.dart without a name conflict.
extension ExtendedForecastStrings on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
