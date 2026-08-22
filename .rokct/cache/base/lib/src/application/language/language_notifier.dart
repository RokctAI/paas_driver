// Copyright (c) 2026 RokctAI
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


import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/settings.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
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

          // Otherwise, find the index of the current language
          for (int i = 0; i < languages.length; i++) {
            if (languages[i].id == lang?.id) {
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
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
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
