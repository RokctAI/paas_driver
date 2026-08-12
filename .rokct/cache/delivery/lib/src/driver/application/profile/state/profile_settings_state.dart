import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/request_model_data.dart';


part 'profile_settings_state.freezed.dart';

@freezed
class ProfileSettingsState with _$ProfileSettingsState {
  const factory ProfileSettingsState({
    @Default(false) bool isLoading,
    ProfileData? userData,
    RequestModelData? requestData,
  }) = _ProfileSettingsState;

  const ProfileSettingsState._();
}
