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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/models/models.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/application/app_widget/app_state.dart';

class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState()) {
    fetchThemeAndLocale();
  }

  Future<void> fetchThemeAndLocale() async {
    final isDarkMode = LocalStorage.getAppThemeMode();
    final lang = LocalStorage.getLanguage();
    final ltr = LocalStorage.getLangLtr();
    // Cold-start sync: AppStyle.isDark defaults dark-first, so without this
    // the AppStyle-driven surfaces would resolve dark while the Material
    // tree honors a stored light preference (or a light
    // AppTheme.defaultDarkMode). Runs synchronously in the notifier's
    // constructor — before the host MaterialApp's first frame — so both
    // theme systems agree from the start.
    AppStyle.setBrightness(isDarkMode ? Brightness.dark : Brightness.light);
    state = state.copyWith(
      isDarkMode: isDarkMode,
      activeLanguage: lang,
      isLtr: ltr,
    );
  }

  Future<void> changeTheme(bool? isDarkMode) async {
    final dark = isDarkMode ?? false;
    await LocalStorage.setAppThemeMode(dark);
    // Keep AppStyle's mode-resolving tokens in lockstep for every caller —
    // not just the profile toggle, which also sets brightness locally.
    AppStyle.setBrightness(dark ? Brightness.dark : Brightness.light);
    state = state.copyWith(isDarkMode: dark);
  }

  Future<void> changeLocale(LanguageData? language) async {
    await LocalStorage.setLanguageData(language);
    await LocalStorage.setLangLtr(language?.backward);
    state = state.copyWith(
      activeLanguage: language,
      isLtr: !(language?.backward ?? false),
    );
  }
}
