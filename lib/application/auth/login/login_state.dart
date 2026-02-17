import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default(false) bool isLoading,
    @Default(false) bool showPassword,
    @Default(false) bool isKeepLogin,
    @Default(false) bool isLoginError,
    @Default(false) bool isEmailNotValid,
    @Default(false) bool isPasswordNotValid,
    @Default(false) bool isGoogleLoading,
    @Default('') String email,
    @Default('') String password,
    @Default(false) bool isPhoneNotValid,
  }) = _LoginState;

  const LoginState._();
}
