import 'package:freezed_annotation/freezed_annotation.dart';


import '../../../../infrastructure/models/models.dart';

part 'profile_settings_state.freezed.dart';

@freezed
class ProfileSettingsState with _$ProfileSettingsState {
  const factory ProfileSettingsState({
    @Default(false) bool isLoading,
    @Default(false) bool isStatisticLoading,
    UserData? userData,
    RequestModelData? requestData,
    StatisticsResponse? statistics,
  }) = _ProfileSettingsState;

  const ProfileSettingsState._();
}
