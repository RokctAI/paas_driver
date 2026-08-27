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

import 'package:get_it/get_it.dart';

/// weather_sdk's DI entry point, called from the host app's generated
/// `main()` (the composer emits a `WeatherSdkDependencies.register(...)`
/// call for every SDK it composes).
///
/// Deliberately registers nothing: the weather suite is riverpod-provider
/// wired end to end (`weatherProvider` / `openWeatherProvider` own their
/// services), and its only host seam is a plain callback -
/// [WeatherSdkConfig.locationResolver] - which the installed
/// `components/weather/weather_widget.dart` template assigns at startup.
/// A GetIt facade would duplicate that one-function seam for no gain.
class WeatherSdkDependencies {
  static void register(GetIt getIt) {
    // Intentionally empty - see class doc.
  }
}
