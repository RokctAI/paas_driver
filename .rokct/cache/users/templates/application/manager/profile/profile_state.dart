// Ported from paas_manager lib/application/profile/profile_state.dart
// (users_sdk manager consume, fork plan S-2 / migration bucket b).
// Trimmed to the fields the composed manager surfaces actually read:
// the retired become-seller CreateShopPage flow (bgImage/logoImage/
// filepath/isSaveLoading/typeIndex/addressModel) is replaced by
// merchants_sdk's shop-setup registration step, and referral/wallet
// history never shipped in the manager shell.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:base_sdk/src/models/data/profile_data.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(true) bool isLoading,
    @Default(null) ProfileData? userData,
  }) = _ProfileState;

  const ProfileState._();
}
