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

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:weather_sdk/weather_sdk.dart';

/// Driver-host weather wiring, installed by weather_sdk's manifest
/// `app_type.driver` block to
/// `lib/presentation/components/weather/weather_widget.dart` - the same
/// destination the generic `weather_widget.dart` template uses, so driver
/// composes get this courier-aware wiring while every other host keeps the
/// generic (shop-location) file. Same two jobs as the generic template:
///
/// 1. [configureWeatherSdk] - one-time startup hook that tells the SDK
///    where the courier is. Called from the driver flavor's `boot_hooks`
///    entry (driver shells embed no weather header widget, so nothing else
///    would run it before the severe-weather banner's first fetch).
///    The courier's live position rides base_sdk's selected-address slot:
///    delivery_sdk's courier home persists the map position through
///    `CourierStorage.saveSelectedLocation` ->
///    `LocalStorage.setAddressSelected`, and the courier pages read it back
///    through the `AddressData.latitude`/`longitude` getters - this
///    resolver reads the exact same slot (ADR-005: base_sdk only, no
///    delivery_sdk import). No stored position yet returns null, which
///    falls back to the DEMO_LATITUDE/DEMO_LONGITUDE dart-defines.
/// 2. [AppWeatherWidget] - kept identical to the generic template so
///    anything importing the installed path keeps compiling in driver
///    hosts.
bool _configured = false;

void configureWeatherSdk() {
  if (_configured) return;
  _configured = true;

  WeatherSdkConfig.locationResolver = () {
    final address = LocalStorage.getAddressSelected();
    final latitude = address?.latitude;
    final longitude = address?.longitude;
    if (latitude != null && longitude != null) {
      return WeatherLocation(latitude: latitude, longitude: longitude);
    }
    // Courier position not stored yet: fall back to the
    // DEMO_LATITUDE/DEMO_LONGITUDE dart-defines.
    return null;
  };
}

/// Embeddable adaptive weather widget for this app's shell.
class AppWeatherWidget extends StatelessWidget {
  /// See [WeatherWidget.inlineExpansion]: pass false when embedding in a
  /// fixed-height header and place [WeatherInlineForecast] in the body
  /// instead.
  final bool inlineExpansion;

  const AppWeatherWidget({super.key, this.inlineExpansion = true});

  @override
  Widget build(BuildContext context) {
    configureWeatherSdk();
    return WeatherWidget(inlineExpansion: inlineExpansion);
  }
}
