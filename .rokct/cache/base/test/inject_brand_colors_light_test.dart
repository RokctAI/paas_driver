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

// AppStyle.injectBrandColors light-mode parameters: a composed app can now
// set its light palette as well as its dark one. Injecting light values
// changes only the light-mode tokens; a call that passes no light value
// leaves light mode exactly as it was.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// Every mode-resolving token injectBrandColors backs, read in [b].
List<Color> _tokens(Brightness b) {
  AppStyle.setBrightness(b);
  return [
    AppStyle.surfaceDark,
    AppStyle.cardDark,
    AppStyle.cardDarkAlt,
    AppStyle.strokeDark,
    AppStyle.strokeDarkSubtle,
    AppStyle.textDarkSecondary,
    AppStyle.textDarkFaint,
    AppStyle.textPrimary,
  ];
}

/// Puts back the values captured before a test, so the statics do not
/// leak into the next one.
void _restore(Color primary, List<Color> dark, List<Color> light) {
  AppStyle.injectBrandColors(
    primary: primary,
    surfaceDark: dark[0],
    cardDark: dark[1],
    cardDarkAlt: dark[2],
    strokeDark: dark[3],
    strokeDarkSubtle: dark[4],
    textDarkSecondary: dark[5],
    textDarkFaint: dark[6],
    inkDark: dark[7],
    surfaceLight: light[0],
    cardLight: light[1],
    cardLightAlt: light[2],
    strokeLight: light[3],
    strokeLightSubtle: light[4],
    textLightSecondary: light[5],
    textLightFaint: light[6],
    inkLight: light[7],
  );
}

void main() {
  late Color primaryBefore;
  late List<Color> darkBefore;
  late List<Color> lightBefore;

  setUp(() {
    primaryBefore = AppStyle.primary;
    darkBefore = _tokens(Brightness.dark);
    lightBefore = _tokens(Brightness.light);
  });

  tearDown(() {
    _restore(primaryBefore, darkBefore, lightBefore);
    AppStyle.setBrightness(Brightness.dark);
  });

  const injected = [
    Color(0xFFEEF3EE),
    Color(0xFFFBFCFA),
    Color(0xFFF2F5F1),
    Color(0xFFD6DDD6),
    Color(0xFFE3E9E3),
    Color(0xFF5B6660),
    Color(0xFF8B958F),
    Color(0xFF15201B),
  ];

  test('light values change the light tokens and leave the dark ones alone',
      () {
    AppStyle.injectBrandColors(
      surfaceLight: injected[0],
      cardLight: injected[1],
      cardLightAlt: injected[2],
      strokeLight: injected[3],
      strokeLightSubtle: injected[4],
      textLightSecondary: injected[5],
      textLightFaint: injected[6],
      inkLight: injected[7],
    );

    expect(_tokens(Brightness.light), injected);
    expect(_tokens(Brightness.dark), darkBefore);

    // The explicit-brightness resolvers and the pinned light surface follow.
    expect(AppStyle.surfaceFor(Brightness.light), injected[0]);
    expect(AppStyle.cardFor(Brightness.light), injected[1]);
    expect(AppStyle.cardAltFor(Brightness.light), injected[2]);
    expect(AppStyle.strokeFor(Brightness.light), injected[3]);
    expect(AppStyle.subtleStrokeFor(Brightness.light), injected[4]);
    expect(AppStyle.secondaryInkFor(Brightness.light), injected[5]);
    expect(AppStyle.faintFor(Brightness.light), injected[6]);
    expect(AppStyle.inkFor(Brightness.light), injected[7]);
    expect(AppStyle.surfaceLightRaw, injected[0]);
    expect(AppStyle.surfaceDarkRaw, darkBefore[0]);
  });

  test('a dark-only call (the existing callers) changes nothing in light mode',
      () {
    AppStyle.injectBrandColors(
      primary: const Color(0xFFF0643C),
      surfaceDark: const Color(0xFF0B1F1A),
      cardDark: const Color(0xFF10302A),
      cardDarkAlt: const Color(0xFF0D2923),
      strokeDark: const Color(0xFF255548),
      strokeDarkSubtle: const Color(0xFF1A3F35),
      textDarkSecondary: const Color(0xFF9DB8AE),
      textDarkFaint: const Color(0xFF6B8C80),
    );

    expect(_tokens(Brightness.light), lightBefore);
    expect(_tokens(Brightness.dark), isNot(darkBefore));
  });

  test('a call with no parameters changes nothing in either mode', () {
    AppStyle.injectBrandColors();

    expect(_tokens(Brightness.light), lightBefore);
    expect(_tokens(Brightness.dark), darkBefore);
  });

  test('the light defaults are the kernel neutral theme until injected', () {
    expect(_tokens(Brightness.light), const [
      Color(0xFFECECEF),
      Color(0xFFF9F9FB),
      Color(0xFFF1F1F4),
      Color(0xFFD9D9DE),
      Color(0xFFE4E4E9),
      Color(0xFF5B5B62),
      Color(0xFF8C8C94),
      Color(0xFF1B1B20),
    ]);
  });
}
