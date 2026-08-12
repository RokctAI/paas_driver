import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_edit_state.freezed.dart';

@freezed
class ProfileEditState with _$ProfileEditState {
  const factory ProfileEditState({
    @Default(false) bool isLoading,
    @Default(true) bool isEmailEditable,
    @Default(true) bool isPhoneEditable,
    @Default(false) bool isFirstnameError,
    @Default(false) bool isLastnameError,
    @Default(false) bool isPasswordError,
    @Default(false) bool isConfirmPasswordError,
    @Default(false) bool showPassword,
    @Default(false) bool showConfirmPassword,
    @Default('') String firstname,
    @Default('') String lastname,
    @Default('') String phone,
    @Default('') String email,
    @Default('') String password,
    @Default('') String confirmPassword,
  }) = _ProfileEditState;

  const ProfileEditState._();
}
