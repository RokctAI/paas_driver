import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/models/models.dart';

import 'package:base_sdk/src/handlers/token_refresh_service.dart';

import 'package:auth_sdk/src/common/domain/interface/deferred_otp_email_resend.dart';
import 'package:auth_sdk/src/common/domain/interface/session_password_rotation.dart';
import 'package:auth_sdk/src/common/domain/interface/session_token_refresh.dart';

class AuthRepository
    implements
        AuthRepositoryFacade,
        DeferredOtpEmailResend,
        SessionPasswordRotation,
        SessionTokenRefresh {
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
      final client = dioHttp.client(requireAuth: false);
      // NOTE: Frappe's core login endpoint is `/api/method/login`
      // NOTE: Using custom PaaS login endpoint to match frontend behavior
      final response = await client.post(
        '/api/method/paas.api.user.login',
        data: {'usr': email, 'pwd': password},
      );
      // Assuming a successful login returns user data that can be adapted to LoginResponse
      // This part will need careful adaptation based on the actual Frappe response
      return ApiResult.success(data: LoginResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/paas.api.user.send_phone_verification_code',
        data: data,
      );
      // The response from this endpoint is simple, may need to adjust RegisterResponse model
      return ApiResult.success(data: RegisterResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.tenant.api.verify_my_email',
        queryParameters: {'token': verifyCode},
      );
      return ApiResult.success(
        data: VerifyPhoneResponse.fromJson(response.data),
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
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/paas.api.user.verify_phone_code',
        data: {"phone": verifyId, "otp": verifyCode},
      );
      return ApiResult.success(
        data: VerifyPhoneResponse.fromJson(response.data),
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
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/paas.api.user.forgot_password',
        data: {'user': email},
      );
      return ApiResult.success(data: RegisterResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: false);
      var res = await client.post(
        '/api/method/paas.api.user.register_user',
        data: user.toJsonForSignUp(),
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
        data: VerifyData.fromJson(res.data['data'] ?? res.data),
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
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/paas.api.user.forgot_password_confirm',
        data: {'verify_code': verifyCode, 'email': email},
      );
      return ApiResult.success(
        data: VerifyData.fromJson(response.data['data'] ?? response.data),
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
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/paas.api.user.login_with_google',
        data: {
          'email': email,
          'display_name': displayName,
          'id': id,
          'avatar': avatar,
        },
      );
      return ApiResult.success(data: LoginResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: false);
      await client.post(
        '/api/method/paas.api.user.register_user',
        data: {'email': email},
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
      final client = dioHttp.client(requireAuth: false);
      await client.post(
        '/api/method/paas.api.user.resend_verification_email',
        data: {'email': email},
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        // The registered composed alias is paas.api.user.update_password
        // (users/frappe manifest whitelisted_methods) — NOT
        // paas.api.user.user.update_password, the raw module path.
        '/api/method/paas.api.user.update_password',
        data: {
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
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/paas.api.user.register_user',
        data: user.toJsonForSignUp(),
      );
      return ApiResult.success(
        data: VerifyData.fromJson(response.data['data'] ?? response.data),
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
