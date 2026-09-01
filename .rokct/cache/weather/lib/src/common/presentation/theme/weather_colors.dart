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
