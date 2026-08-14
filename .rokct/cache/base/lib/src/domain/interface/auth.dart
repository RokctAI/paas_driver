import 'package:base_sdk/src/models/models.dart';

import 'package:base_sdk/src/handlers/handlers.dart';

abstract class AuthRepositoryFacade {
  Future<ApiResult<LoginResponse>> login({
    required String email,
    required String password,
  });

  Future<ApiResult<LoginResponse>> loginWithGoogle({
    required String email,
    required String displayName,
    required String id,
    required String avatar,
  });

  Future<ApiResult<dynamic>> sigUp({required String email});

  /// [idempotencyKey], when provided, is sent as `X-Idempotency-Key` so the
  /// server-side @idempotent register endpoint replays a retried upload
  /// instead of double-registering. Callers pass a key that is stable
  /// across retries of the same registration (e.g. the offline row id), or
  /// null to send no header.
  Future<ApiResult<VerifyData>> sigUpWithData({
    required UserModel user,
    String? idempotencyKey,
  });

  Future<ApiResult<VerifyData>> sigUpWithPhone({required UserModel user});

  Future<ApiResult<RegisterResponse>> sendOtp({required String phone});

  Future<ApiResult<RegisterResponse>> forgotPassword({required String email});

  Future<ApiResult<VerifyPhoneResponse>> verifyEmail({
    required String verifyCode,
  });

  Future<ApiResult<VerifyPhoneResponse>> verifyPhone({
    required String verifyCode,
    required String verifyId,
  });

  Future<ApiResult<VerifyData>> forgotPasswordConfirm({
    required String verifyCode,
    required String email,
  });

  Future<ApiResult<VerifyData>> forgotPasswordConfirmWithPhone({
    required String phone,
  });
}
