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

part 'register_confirmation_state.freezed.dart';

@freezed
abstract class RegisterConfirmationState with _$RegisterConfirmationState {
  const factory RegisterConfirmationState({
    @Default(false) bool isLoading,
    @Default(false) bool isSuccess,
    @Default(false) bool isResetPasswordSuccess,
    @Default(false) bool isResending,
    @Default(false) bool isTimeExpired,
    @Default(false) bool isCodeError,
    @Default(false) bool isConfirm,
    @Default('') String confirmCode,
    @Default('') String verificationCode,
    @Default('05:00') String timerText,
  }) = _RegisterConfirmationState;

  const RegisterConfirmationState._();
}
