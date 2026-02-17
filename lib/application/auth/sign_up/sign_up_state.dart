import 'package:freezed_annotation/freezed_annotation.dart';
part 'sign_up_state.freezed.dart';

@freezed
class SignUpState with _$SignUpState {
  const factory SignUpState({
    @Default(false) bool isLoading,
    @Default(false) bool showPassword,
    @Default(true) bool isKeepLogin,
    @Default(false) bool isLoginError,
    @Default(false) bool isGoogleLoading,
    @Default(false) bool isSuccess,
    @Default(false) bool showConfirmPassword,
    @Default(false) bool isEmailInvalid,
    @Default(false) bool isPasswordInvalid,
    @Default(false) bool isConfirmPasswordInvalid,
    @Default(false) bool isPhoneInvalid,
    @Default(false) bool isFirstNameInvalid,
    @Default(false) bool isSurNameInvalid,
    @Default('') String phone,
    @Default('') String verificationId,
    @Default('') String email,
    @Default('') String referral,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String password,
    @Default('') String confirmPassword,
  }) = _SignUpState;

  const SignUpState._();
}
