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

import 'dart:convert';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/theme/map_themes.dart';

/// The driver maps' style, resolved with the mode.
///
/// Tablet audit 2026-09-07: the driver home (05-driver_home) rendered LIGHT
/// in dark mode - every other surface of the page resolves through
/// `AppStyle`, but the `GoogleMap` under them shipped with no style at all,
/// so the native map painted Google's daylight tiles under dark chrome.
/// The delivery-zone editor's map had the same gap.
///
/// The night style is base_sdk's own [AppMapThemes.mapDarkTheme] (dark
/// geometry, muted labels - the standard Google night JSON), which base has
/// carried unused since the refork. It is encoded ONCE here, because
/// `GoogleMap.style` takes the JSON string, not the list, and both driver
/// map pages (home, delivery zone) read it through [forMode] so they can
/// never disagree.
///
/// Light mode gets `null` - Google's default daylight style, exactly what
/// the maps drew before - so nothing changes for a driver on the light
/// theme. Base also ships a `mapLightTheme`; no page of the fleet applies it
/// today and this is a dark-mode fix, not a light-mode redesign.
///
/// The home page's off-duty desaturation stays a paint-time
/// `ColorFiltered` over the map (see `_map` there): it is a state overlay,
/// not a theme, and it composes over either style.
abstract final class DriverMapStyle {
  /// The night style as the JSON `GoogleMap.style` accepts.
  static final String dark = jsonEncode(AppMapThemes.mapDarkTheme);

  /// [dark] while [AppStyle.isDark], null (the plugin's daylight default)
  /// otherwise. Read at build time, so a map that is still mounted when the
  /// theme toggle flips the mode picks the new style up on its next build
  /// (`style` is part of the plugin's live map configuration).
  static String? forMode() => AppStyle.isDark ? dark : null;
}
