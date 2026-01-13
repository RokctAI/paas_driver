import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../infrastructure/models/models.dart';

part 'languages_state.freezed.dart';

@freezed
class LanguageState with _$LanguageState {
  const factory LanguageState({
    @Default([]) List<LanguageData> list,
    @Default(0) int index,
    @Default(true) bool isLoading,
    @Default(false) bool isSuccess,
    @Default(true) bool isSelectLanguage,
  }) = _LanguageState;

  const LanguageState._();
}
