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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'reset_password_state.freezed.dart';

@freezed
abstract class ResetPasswordState with _$ResetPasswordState {
  const factory ResetPasswordState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    @Default(false) bool isEmailError,
    @Default(false) bool isPasswordInvalid,
    @Default(false) bool isConfirmPasswordInvalid,
    @Default(false) bool showPassword,
    @Default(false) bool showConfirmPassword,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String verifyId,
    @Default('') String password,
    @Default('') String confirmPassword,
  }) = _ResetPasswordState;

  const ResetPasswordState._();
}
