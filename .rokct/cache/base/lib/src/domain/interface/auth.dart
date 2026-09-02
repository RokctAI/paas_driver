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
