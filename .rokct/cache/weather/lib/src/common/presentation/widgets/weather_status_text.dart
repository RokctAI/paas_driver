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
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:weather_sdk/src/common/application/weather/weather_state.dart';

/// Ported from pos main's `weather/weather_status_text.dart`.
class WeatherStatusText extends StatelessWidget {
  final WeatherState weatherState;

  const WeatherStatusText({super.key, required this.weatherState});

  String _cleanText(String text) {
    return text.replaceAll(' nearby', '');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 3), (i) => i),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const SizedBox.shrink();

        final cyclePosition =
            snapshot.data! % (weatherState.alerts.isEmpty ? 2 : 3);
        String displayText;
        Color textColor;

        if (weatherState.alerts.isNotEmpty && cyclePosition == 2) {
          displayText = _cleanText(
            weatherState.alerts.first['event'] ?? 'Weather Alert',
          );
          textColor = AppStyle.red;
        } else if (cyclePosition == 1) {
          displayText = _cleanText(weatherState.condition['text']);
          textColor = AppStyle.textPrimary;
        } else {
          displayText = 'Tomorrow';
          textColor = AppStyle.textPrimary;
        }

        return Padding(
          padding: EdgeInsets.only(top: 0.5.sp),
          child: Text(
            displayText,
            style: TextStyle(fontSize: 10.sp, color: textColor, height: 1),
          ),
        );
      },
    );
  }
}
