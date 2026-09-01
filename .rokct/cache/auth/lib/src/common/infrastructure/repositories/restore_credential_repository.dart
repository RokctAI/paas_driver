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
// in base_sdk http_service.dart)

import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

/// Client for the WebAuthn relying-party endpoints that back Android's
/// Restore Credentials.
///
/// A separate class rather than more methods on [AuthRepository] on
/// purpose: AuthRepository implements base_sdk's `AuthRepositoryFacade`,
/// which every consuming app depends on, and widening that interface would
/// break each of them. Nothing here touches the existing SDK surface.
///
/// Every call is a POST to the single platform gateway with a prefix-free
/// `cmd` -- the auth module manifest's whitelisted-method key with the app
/// segment dropped, exactly like `api.auth.refresh`.
class RestoreCredentialRepository {
  const RestoreCredentialRepository();

  static const _gateway = PlatformGateway();

  /// Creation options for a new restore key.
  ///
  /// Session-authenticated: the backend binds the resulting credential to
  /// the signed-in account and ignores anything the client says about who
  /// it is, so this can only ever mint a key for the caller themselves.
  Future<ApiResult<Map<String, dynamic>>> registrationOptions() async {
    try {
      final response = await _gateway.call(
        'api.auth.restore_register_options',
      );
      return ApiResult.success(data: _publicKeyOf(response));
    } catch (e) {
      debugPrint('==> restore registration options failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Hand the platform's `RegistrationResponseJSON` back for verification.
  Future<ApiResult<dynamic>> registrationVerify(
    Map<String, dynamic> credential,
  ) async {
    try {
      await _gateway.call(
        'api.auth.restore_register_verify',
        payload: {'credential': credential},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> restore registration verify failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Request options for signing in with a restore key.
  ///
  /// `requireAuth: false` because this necessarily runs before there is a
  /// session -- that is the entire point of a restore. The endpoint hands
  /// out nothing but a random challenge.
  Future<ApiResult<Map<String, dynamic>>> assertionOptions() async {
    try {
      final response = await _gateway.call(
        'api.auth.restore_assert_options',
        requireAuth: false,
      );
      return ApiResult.success(data: _publicKeyOf(response));
    } catch (e) {
      debugPrint('==> restore assertion options failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Verify the platform's `AuthenticationResponseJSON` and, on success,
  /// receive an ordinary session in exactly the shape `api.user.login`
  /// returns -- so the caller can reuse [LoginResponse] unchanged.
  Future<ApiResult<LoginResponse>> assertionVerify(
    Map<String, dynamic> credential,
  ) async {
    try {
      final response = await _gateway.call(
        'api.auth.restore_assert_verify',
        payload: {'credential': credential},
        requireAuth: false,
      );
      return ApiResult.success(data: LoginResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> restore assertion verify failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Drop the server's copy of the signed-in account's restore key.
  ///
  /// Pairs with the platform-side delete on sign-out and account deletion:
  /// the app forgets the key and so does the backend, so a later restore
  /// cannot resurrect the session from either side.
  Future<ApiResult<dynamic>> revoke() async {
    try {
      await _gateway.call('api.auth.restore_revoke');
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> restore revoke failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Both options endpoints answer `{data: {publicKey: {...}}}`, and
  /// base_sdk's response interceptor has already unwrapped the envelope's
  /// top-level `message` key by the time we see it. Tolerate either depth
  /// rather than assuming one.
  static Map<String, dynamic> _publicKeyOf(dynamic response) {
    final Map<String, dynamic> body =
        response is Map<String, dynamic> ? response : <String, dynamic>{};
    final dynamic data = body['data'] ?? body;
    if (data is Map && data['publicKey'] is Map) {
      return Map<String, dynamic>.from(data['publicKey'] as Map);
    }
    return <String, dynamic>{};
  }
}
