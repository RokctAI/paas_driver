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

// compliance-ignore-file: obs-flutter-trace
// Pure mapper: it builds an icon asset URL string and maps icon codes to
// widgets; it makes no HTTP calls and holds no client. Flagged solely
// because it lives under infrastructure/services/.

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class OpenWeatherIconMapper {
  static String getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  static IconData getRemixIcon(String iconCode) {
    // For daily forecast, we'll use the day version of icons
    final baseCode = iconCode.substring(0, 2); // Get main weather code

    switch (baseCode) {
      // Clear sky
      case '01':
        return Remix.sun_fill;

      // Few clouds
      case '02':
        return Remix.sun_cloudy_fill;

      // Scattered clouds
      case '03':
        return Remix.cloudy_fill;

      // Broken clouds
      case '04':
        return Remix.cloud_fill;

      // Shower rain
      case '09':
        return Remix.showers_fill;

      // Rain
      case '10':
        return Remix.heavy_showers_fill;

      // Thunderstorm
      case '11':
        return Remix.thunderstorms_fill;

      // Snow
      case '13':
        return Remix.snowy_fill;

      // Mist, fog, etc.
      case '50':
        return Remix.mist_fill;

      default:
        return Remix.sun_cloudy_fill;
    }
  }

  static bool isSevereCondition(String iconCode) {
    final baseCode = iconCode.substring(0, 2);
    return [
      '11', // Thunderstorm
    ].contains(baseCode);
  }

  static bool isPrecipitation(String iconCode) {
    final baseCode = iconCode.substring(0, 2);
    return [
      '09', // Shower rain
      '10', // Rain
      '11', // Thunderstorm
      '13', // Snow
    ].contains(baseCode);
  }

  // Helper method to get a description for the icon code
  static String getWeatherDescription(String iconCode) {
    final baseCode = iconCode.substring(0, 2);
    switch (baseCode) {
      case '01':
        return 'Clear sky';
      case '02':
        return 'Few clouds';
      case '03':
        return 'Scattered clouds';
      case '04':
        return 'Broken clouds';
      case '09':
        return 'Shower rain';
      case '10':
        return 'Rain';
      case '11':
        return 'Thunderstorm';
      case '13':
        return 'Snow';
      case '50':
        return 'Mist';
      default:
        return 'Unknown';
    }
  }
}
