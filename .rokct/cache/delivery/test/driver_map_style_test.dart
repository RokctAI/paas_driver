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

// The driver maps' style resolves with the mode (tablet audit 2026-09-07,
// 05-driver_home LIGHT in dark mode): dark mode gets base_sdk's night JSON,
// light mode gets the plugin's daylight default (null), and the dark JSON
// is a real style - dark geometry, muted labels - not an empty list.

import 'dart:convert';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/theme/map_themes.dart';
import 'package:delivery_sdk/src/driver/presentation/widgets/driver_map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final wasDark = AppStyle.isDark;
  tearDown(() => AppStyle.isDark = wasDark);

  test('dark mode applies the night style', () {
    AppStyle.setBrightness(Brightness.dark);
    expect(DriverMapStyle.forMode(), DriverMapStyle.dark);
  });

  test('light mode keeps the plugin default', () {
    AppStyle.setBrightness(Brightness.light);
    expect(DriverMapStyle.forMode(), isNull);
  });

  test('the night style is base_sdk\'s dark map theme, encoded', () {
    final decoded = jsonDecode(DriverMapStyle.dark) as List<dynamic>;
    expect(decoded, isNotEmpty);
    expect(decoded.length, AppMapThemes.mapDarkTheme.length);
    final geometry = decoded.first as Map<String, dynamic>;
    expect(geometry['elementType'], 'geometry');
    expect(geometry['stylers'], [
      {'color': '#242f3e'},
    ]);
  });
}
