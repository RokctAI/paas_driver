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

/// UV-index badge severity accents — the ONLY colors weather_sdk still owns.
///
/// Per Ray's decision, harvested pos surfaces carry no palette of their own:
/// every surface/ink/stroke color in this SDK resolves through base_sdk's
/// `AppStyle` mode-resolving tokens (`textPrimary`, `cardDark`, `cardDarkAlt`,
/// `strokeDark*`, `textDarkSecondary`, ...) so light/dark follow the host's
/// theme exactly like supacharge.
///
/// The two constants below survive because they are weather-domain SEMANTICS,
/// not palette: the UV severity scale (moderate -> high -> very high ->
/// extreme) needs fixed warning hues that read identically in both themes,
/// and base_sdk's AppStyle has no UV/warning-scale tokens. The rest of the
/// scale maps to themed tokens (moderate = `AppStyle.textDarkSecondary`,
/// low = `AppStyle.textPrimary`) and extreme = `AppStyle.red`.
abstract class WeatherColors {
  WeatherColors._();

  /// "High" UV badge (amber step of the UV severity scale).
  static const Color uvHigh = Color(0xFFFFC107);

  /// "Very high" UV badge (orange step of the UV severity scale).
  static const Color uvVeryHigh = Color(0xFFF26110);
}
