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
