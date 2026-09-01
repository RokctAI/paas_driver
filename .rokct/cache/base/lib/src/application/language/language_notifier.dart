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


import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/bundled_translations.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/common/translation_seeder.dart';
// [refork] removed host router import

import 'package:base_sdk/src/application/language/language_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class LanguageNotifier extends StateNotifier<LanguageState> {
  final SettingsRepositoryFacade _settingsRepository;

  LanguageNotifier(this._settingsRepository) : super(const LanguageState());

  void change(int index) {
    state = state.copyWith(index: index);
    LocalStorage.setLanguageData(state.list[index]);
  }

  Future<void> getLanguages(
    BuildContext context, {
    bool autoSelectIfSingle = false,
  }) async {
    final connect = await AppConnectivity.connectivity();
    if (connect) {
      state = state.copyWith(isLoading: true, isSuccess: false);
      final response = await _settingsRepository.getLanguages();
      response.when(
        success: (data) {
          final List<LanguageData> languages = data.data ?? [];
          final lang = LocalStorage.getLanguage();
          int index = 0;

          // If there's only one language and autoSelectIfSingle is true,
          // automatically select it and skip language selection
          if (languages.length == 1 && autoSelectIfSingle) {
            LocalStorage.setLanguageSelected(true);
            LocalStorage.setLanguageData(languages[0]);
            LocalStorage.setLangLtr(languages[0].backward);
            getTranslations(context);
            state = state.copyWith(
              isLoading: false,
              list: languages,
              index: 0,
              isSuccess: true,
              autoSelected: true,
            );
            return;
          }

          // Otherwise, find the index of the current language. Guard on a
          // non-null stored id so two missing ids never read as a match.
          for (int i = 0; i < languages.length; i++) {
            if (lang?.id != null && languages[i].id == lang?.id) {
              index = i;
              break;
            }
          }

          state = state.copyWith(
            isLoading: false,
            list: languages,
            index: index,
          );
        },
        failure: (failure, status) {
          // Backend language list unreachable: fall back to the locally
          // bundled languages (English + every locale with a bundled
          // translation map) so the picker still works offline. A
          // successful backend response above stays authoritative.
          if (!_applyBundledLanguageFallback()) {
            state = state.copyWith(isLoading: false);
            AppHelpers.showCheckTopSnackBar(context, failure);
          }
        },
      );
    } else {
      if (!_applyBundledLanguageFallback() && context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  /// Populates the picker from [BundledTranslations.fallbackLanguages]
  /// when the backend list could not be fetched. Keeps the currently
  /// stored language selected when its locale is in the fallback list.
  /// Returns false when there is nothing to fall back to.
  bool _applyBundledLanguageFallback() {
    final languages = BundledTranslations.fallbackLanguages();
    if (languages.isEmpty) return false;
    final storedLocale = LocalStorage.getLanguage()?.locale;
    int index = 0;
    for (int i = 0; i < languages.length; i++) {
      if (storedLocale != null && languages[i].locale == storedLocale) {
        index = i;
        break;
      }
    }
    state = state.copyWith(isLoading: false, list: languages, index: index);
    return true;
  }

  Future<void> makeSelectedLang(BuildContext context) async {
    LocalStorage.setLanguageSelected(true);
    LocalStorage.setLanguageData(state.list[state.index]);
    LocalStorage.setLangLtr(state.list[state.index].backward);
    await getTranslations(context);
  }

  Future<void> getTranslations(BuildContext context) async {
    final connect = await AppConnectivity.connectivity();
    if (connect) {
      state = state.copyWith(isLoading: true, isSuccess: false);
      final response = await _settingsRepository.getMobileTranslations();
      response.when(
        success: (data) {
          LocalStorage.setTranslations(data.data);
          // Fire-and-forget: offer the app's bundled translation keys to
          // the backend (insert-only server-side); silent on failure.
          TranslationSeeder.pushMissingKeys();
          state = state.copyWith(isLoading: false, isSuccess: true);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppRoutes.I.replaceNoConnectionRoute(context);
      }
    }
  }
}
