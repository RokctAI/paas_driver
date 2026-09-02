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

// compliance-ignore-file: flutter-http-timeout (no HTTP client is constructed
// or configured in this file: every call rides base_sdk's PlatformGateway,
// whose shared Dio client sets connectTimeout/receiveTimeout/sendTimeout (30s)
// in base_sdk http_service.dart; the dio import here exists only for Options,
// used to stamp the X-Idempotency-Key header)

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/models/models.dart';

import 'package:base_sdk/src/handlers/token_refresh_service.dart';

import 'package:auth_sdk/src/common/domain/interface/deferred_otp_email_resend.dart';
import 'package:auth_sdk/src/common/domain/interface/session_password_rotation.dart';
import 'package:auth_sdk/src/common/domain/interface/session_token_refresh.dart';
import 'package:auth_sdk/src/common/services/registration_config.dart';

class AuthRepository
    implements
        AuthRepositoryFacade,
        DeferredOtpEmailResend,
        SessionPasswordRotation,
        SessionTokenRefresh {
  /// Universal platform gateway: every backend call is a POST to the single
  /// gateway endpoint with a prefix-free `cmd`. Cmds are the users/auth
  /// modules' `manifest.json` whitelisted-method keys with the app segment
  /// dropped (`api.user.*`, `tenant.api.*`).
  static const _gateway = PlatformGateway();

  // SessionTokenRefresh: delegates to base_sdk's single-flight service so
  // an explicit renewal and the automatic 401/expiry path can never race.
  @override
  Future<bool> refreshSession() => TokenRefreshService.refresh();

  @override
  Future<ApiResult<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      // NOTE: Frappe's core login endpoint is `/api/method/login`; this is
      // the platform's own login cmd, which mints the Bearer token pair in
      // the JSON body — so it rides the gateway envelope like any other cmd.
      final response = await _gateway.call(
        'api.user.login',
        payload: {'usr': email, 'pwd': password},
        requireAuth: false,
      );
      // Assuming a successful login returns user data that can be adapted to LoginResponse
      // This part will need careful adaptation based on the actual Frappe response
      return ApiResult.success(data: LoginResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> login failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<RegisterResponse>> sendOtp({required String phone}) async {
    final data = {'phone': phone.replaceAll('+', "")};
    try {
      final response = await _gateway.call(
        'api.user.send_phone_verification_code',
        payload: data,
        requireAuth: false,
      );
      // The response from this endpoint is simple, may need to adjust RegisterResponse model
      return ApiResult.success(data: RegisterResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> send otp failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<VerifyPhoneResponse>> verifyEmail({
    required String verifyCode,
  }) async {
    try {
      // Formerly a GET with a `token` query parameter; the gateway carries
      // the same argument as payload kwargs.
      final response = await _gateway.call(
        'tenant.api.verify_my_email',
        payload: {'token': verifyCode},
        requireAuth: false,
      );
      return ApiResult.success(
        data: VerifyPhoneResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> verify email failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<VerifyPhoneResponse>> verifyPhone({
    required String verifyId,
    required String verifyCode,
  }) async {
    try {
      final response = await _gateway.call(
        'api.user.verify_phone_code',
        payload: {"phone": verifyId, "otp": verifyCode},
        requireAuth: false,
      );
      return ApiResult.success(
        data: VerifyPhoneResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> verify phone failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<RegisterResponse>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _gateway.call(
        'api.user.forgot_password',
        payload: {'user': email},
        requireAuth: false,
      );
      return ApiResult.success(data: RegisterResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> forgot password failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<VerifyData>> sigUpWithData({
    required UserModel user,
    String? idempotencyKey,
  }) async {
    try {
      var res = await _gateway.call(
        'api.user.register_user',
        // The register form's pending terms acceptance + optional birth
        // date ride on top of the fixed UserModel payload (see
        // RegistrationTerms — base_sdk's facade/UserModel cannot widen).
        // Both server params are optional, so the payload stays exactly
        // the old one when the form recorded nothing.
        payload: {
          ...user.toJsonForSignUp(),
          ...RegistrationTerms.signUpExtras(),
        },
        requireAuth: false,
        // register_user is @idempotent server-side: a stable key makes an
        // ambiguous-failure retry replay the stored response instead of
        // double-registering. Callers without a natural stable key send no
        // header (the server tolerates absence).
        options: idempotencyKey == null
            ? null
            : Options(headers: {'X-Idempotency-Key': idempotencyKey}),
      );
      // This response will not contain tokens, adaptation needed
      return ApiResult.success(
        data: VerifyData.fromJson(res['data'] ?? res),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // Finalized implementation for AuthRepository
  // Placeholder for unimplemented methods from the interface
  @override
  Future<ApiResult<VerifyData>> forgotPasswordConfirm({
    required String verifyCode,
    required String email,
  }) async {
    try {
      final response = await _gateway.call(
        'api.user.forgot_password_confirm',
        payload: {'verify_code': verifyCode, 'email': email},
        requireAuth: false,
      );
      return ApiResult.success(
        data: VerifyData.fromJson(response['data'] ?? response),
      );
    } catch (e) {
      debugPrint('==> forgot password confirm failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<VerifyData>> forgotPasswordConfirmWithPhone({
    required String phone,
  }) async {
    // Usually followed by sendOtp and verifyPhone
    return sendOtp(phone: phone).then(
      (value) => value.when(
        success: (data) => ApiResult.success(data: VerifyData()),
        failure: (error, status) =>
            ApiResult.failure(error: error, statusCode: status),
      ),
    );
  }

  @override
  Future<ApiResult<LoginResponse>> loginWithGoogle({
    required String email,
    required String displayName,
    required String id,
    required String avatar,
  }) async {
    try {
      final response = await _gateway.call(
        'api.user.login_with_google',
        payload: {
          'email': email,
          'display_name': displayName,
          'id': id,
          'avatar': avatar,
        },
        requireAuth: false,
      );
      return ApiResult.success(data: LoginResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> login with google failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> sigUp({required String email}) async {
    try {
      await _gateway.call(
        'api.user.register_user',
        payload: {'email': email},
        requireAuth: false,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> signup failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // DeferredOtpEmailResend: email-OTP send for an account that already
  // exists on the backend (deferred/offline-registered, now synced). Sent
  // unauthenticated (requireAuth: false): the endpoint is allow_guest and
  // identifies the account by the email parameter, and at this point in
  // the deferred flow the only stored token may be the local
  // `offline:<id>` placeholder — sending that as a Bearer credential was
  // dishonest and only worked because the backend's Bearer parser happens
  // to fall through to Guest on malformed tokens.
  @override
  Future<ApiResult<dynamic>> resendVerificationEmail({
    required String email,
  }) async {
    try {
      await _gateway.call(
        'api.user.resend_verification_email',
        payload: {'email': email},
        requireAuth: false,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> resend verification email failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // SessionPasswordRotation: set the CURRENT session user's backend
  // password (used to rotate a deferred account's sync-time password to a
  // fresh random secret right after OTP verification mints a real token).
  // Same endpoint the reset-password flow uses via users_sdk, called here
  // directly so auth_sdk doesn't depend on which UserRepositoryFacade
  // implementation the host composed in. Requires a real token —
  // update_password rejects Guest.
  @override
  Future<ApiResult<dynamic>> updateSessionPassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _gateway.tenant(
        // The registered manifest alias key ends in
        // `api.user.update_password` (users/frappe manifest
        // whitelisted_methods) — NOT `api.user.user.update_password`, the
        // raw module path — so that is the prefix-free cmd.
        'api.user.update_password',
        {
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update session password failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<VerifyData>> sigUpWithPhone({
    required UserModel user,
  }) async {
    try {
      final response = await _gateway.call(
        'api.user.register_user',
        // Same terms/birth-date ride-along as sigUpWithData — the phone
        // path is the same register_user endpoint.
        payload: {
          ...user.toJsonForSignUp(),
          ...RegistrationTerms.signUpExtras(),
        },
        requireAuth: false,
      );
      return ApiResult.success(
        data: VerifyData.fromJson(response['data'] ?? response),
      );
    } catch (e) {
      debugPrint('==> signup with phone failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
