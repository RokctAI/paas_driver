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
