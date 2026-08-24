// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'dart:async';

import 'package:base_sdk/src/navigation/app_routes.dart';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/app_validators.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
// [refork] removed host router import

import 'package:auth_sdk/src/common/application/auth/reset_password/reset_password_state.dart';
import 'package:auth_sdk/src/common/services/auth_error_presenter.dart';
import 'package:auth_sdk/src/common/services/platform_support.dart';

class ResetPasswordNotifier extends StateNotifier<ResetPasswordState> {
  final AuthRepositoryFacade _authRepository;
  final UserRepositoryFacade _userRepositoryFacade;

  ResetPasswordNotifier(this._authRepository, this._userRepositoryFacade)
    : super(const ResetPasswordState());

  void setEmail(String text) {
    state = state.copyWith(email: text.trim(), isEmailError: false);
  }

  void setVerifyId(String? value) {
    state = state.copyWith(verifyId: value?.trim() ?? '');
  }

  void setPassword(String password) {
    state = state.copyWith(password: password.trim(), isPasswordInvalid: false);
  }

  void setConfirmPassword(String password) {
    state = state.copyWith(
      confirmPassword: password.trim(),
      isConfirmPasswordInvalid: false,
    );
  }

  void toggleShowPassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void toggleShowConfirmPassword() {
    state = state.copyWith(showConfirmPassword: !state.showConfirmPassword);
  }

  checkEmail() {
    return AppValidators.isValidEmail(state.email);
  }

  Future<void> sendCodeToNumber(BuildContext context) async {
    // Firebase phone verification (the only path this method has) has no
    // desktop implementation — fail fast instead of hanging the spinner.
    if (!isMobilePlatform) {
      AppHelpers.showCheckTopSnackBar(
        context,
        AppHelpers.getTranslation(trPhoneVerificationNotAvailableOnDesktop),
      );
      return;
    }
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true, isSuccess: false);
      if (state.email.trim().isEmpty) {
        state = state.copyWith(isLoading: false, isSuccess: false);
        return;
      }
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: state.email.trim(),
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          // Firebase's error text is third-party provider wording, never
          // student copy — friendly line only, detail to telemetry
          // (entry-56 rule).
          AuthErrorPresenter.showTechnical(
            context,
            type: 'auth_reset_code_send_failed',
            detail: '${e.code}: ${e.message ?? ''}',
            extra: const {'provider': 'firebase'},
          );
          state = state.copyWith(isLoading: false, isSuccess: false);
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            phone: state.email,
            isLoading: false,
            verifyId: verificationId,
            isSuccess: true,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> sendCode(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true, isSuccess: false);
      final response = await _authRepository.forgotPassword(
        email: state.email.trim(),
      );
      response.when(
        success: (data) async {
          state = state.copyWith(
            verifyId: data.data?.verifyId ?? '',
            isLoading: false,
            isSuccess: true,
          );
        },
        failure: (failure, status) {
          state = state.copyWith(
            isLoading: false,
            isEmailError: true,
            isSuccess: false,
          );
          // Was: the bare HTTP status number on screen.
          AuthErrorPresenter.show(
            context,
            type: 'auth_reset_code_send_failed',
            failure: failure,
            statusCode: status,
          );
          debugPrint('==> send otp failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      }
    }
  }

  Future<void> setResetPassword(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (!AppValidators.isValidPassword(state.password)) {
        state = state.copyWith(isPasswordInvalid: true);
        return;
      }
      if (!AppValidators.isValidConfirmPassword(
        state.password,
        state.confirmPassword,
      )) {
        state = state.copyWith(isConfirmPasswordInvalid: true);
        return;
      }
      state = state.copyWith(isLoading: true, isSuccess: false);
      final response = await _userRepositoryFacade.updatePassword(
        password: state.password,
        passwordConfirmation: state.confirmPassword,
      );
      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false, isSuccess: true);
          if (AppConstants.isDemo) {
            AppRoutes.I.replaceUiTypeRoute(context);
          } else {
            AppHelpers.goHome(context);
          }
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false, isSuccess: false);
          if (status == 400) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(
                AppHelpers.getTranslation(TrKeys.emailAlreadyExists),
              ),
            );
          } else {
            // Was: the bare HTTP status number on screen.
            AuthErrorPresenter.show(
              context,
              type: 'auth_password_update_failed',
              failure: failure,
              statusCode: status,
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }
}
