import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/interface/interfaces.dart';
import '../../../infrastructure/models/models.dart';
import '../../../infrastructure/services/services.dart';
import 'languages_state.dart';

class LanguageNotifier extends StateNotifier<LanguageState> {
  final SettingsRepository _settingsRepository;
  LanguageNotifier(this._settingsRepository) : super( const LanguageState());

  void change(int index) {
    state = state.copyWith(index: index);
    LocalStorage.setLanguageData(state.list[index]);
  }
  Future<void> checkLanguage(BuildContext context) async {
    final lang = LocalStorage.getLanguage();
    if (lang == null) {
      state = state.copyWith(isSelectLanguage: false);
    } else {
      final connect = await AppConnectivity.connectivity();
      if (connect) {
        final response = await _settingsRepository.getLanguages();
        response.when(
          success: (data) {
            state = state.copyWith(list: data.data ?? []);
            final List<LanguageData> languages = data.data ?? [];
            for (int i = 0; i < languages.length; i++) {
              if (languages[i].id == lang.id) {
                state = state.copyWith(
                  isSelectLanguage: true,
                );
                break;
              }
            }
          },
          failure: (failure, status) {
            state = state.copyWith(isSelectLanguage: false);
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          },
        );
      } else {
        if (!context.mounted) return;
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> getLanguages(BuildContext context) async {
    final connect = await AppConnectivity.connectivity();
    if (connect) {
      state = state.copyWith(isLoading: true,isSuccess: false);
      final response = await _settingsRepository.getLanguages();
      response.when(
        success: (data) {
          final List<LanguageData> languages = data.data ?? [];
          final lang = LocalStorage.getLanguage();
          int index = 0;
          for (int i = 0; i < languages.length; i++) {
            if (languages[i].id == lang?.id) {
              index = i;
              break;
            }
          }
          state = state.copyWith(
            isLoading: false,
            list: data.data ?? [],
            index: index,
          );
        },
        failure: (failure,status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        },
      );
    } else {
      if (!context.mounted) return;
      AppHelpers.showNoConnectionSnackBar(context);
    }
  }


  Future<void> makeSelectedLang({Function(LanguageData)? afterUpdate,required BuildContext context}) async {
    LocalStorage.setLanguageSelected(true);
    LocalStorage.setLanguageData(state.list[state.index]);
    LocalStorage.setLangLtr(state.list[state.index].backward);
    await getTranslations(
      context: context,
      afterUpdate: () {
        if (afterUpdate != null) {
          afterUpdate(state.list[state.index]);
        }
      },
    );
  }

  Future<void> getTranslations({VoidCallback? afterUpdate,required BuildContext context}) async {
    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      isSelectLanguage: false,
    );
    final response = await _settingsRepository.getTranslations();
    response.when(
      success: (data) {
        LocalStorage.setTranslations(data.data);
        if (afterUpdate != null) {
          afterUpdate();
        }
        state = state.copyWith(isLoading: false, isSuccess: true);
      },
      failure: (failure,status) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
        state = state.copyWith(isLoading: false);
      },
    );
  }
}
