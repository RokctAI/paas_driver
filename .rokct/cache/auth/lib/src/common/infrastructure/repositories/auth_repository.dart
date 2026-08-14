import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/models/models.dart';

import 'package:auth_sdk/src/common/domain/interface/deferred_otp_email_resend.dart';

class AuthRepository implements AuthRepositoryFacade, DeferredOtpEmailResend {
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
        '/api/method/paas.api.user.user.login',
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
        '/api/method/paas.api.send_phone_verification_code',
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
        '/api/method/paas.api.verify_my_email',
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
        '/api/method/paas.api.verify_phone_code',
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
        '/api/method/paas.api.forgot_password',
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
        '/api/method/paas.api.register_user',
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
        '/api/method/paas.api.forgot_password_confirm',
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
        '/api/method/paas.api.login_with_google',
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
        '/api/method/paas.api.register_user',
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
  // exists on the backend (deferred/offline-registered, now synced). The
  // endpoint authorizes against the session user, so this is called with
  // the synced account's own token active (requireAuth: true) — unlike the
  // pre-registration sends above, which run unauthenticated.
  @override
  Future<ApiResult<dynamic>> resendVerificationEmail({
    required String email,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.resend_verification_email',
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

  @override
  Future<ApiResult<VerifyData>> sigUpWithPhone({
    required UserModel user,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/paas.api.register_user',
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
