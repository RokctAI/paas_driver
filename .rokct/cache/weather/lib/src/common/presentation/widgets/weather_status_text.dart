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
