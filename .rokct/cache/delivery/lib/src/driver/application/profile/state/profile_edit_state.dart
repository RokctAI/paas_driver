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

part 'profile_edit_state.freezed.dart';

@freezed
abstract class ProfileEditState with _$ProfileEditState {
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
