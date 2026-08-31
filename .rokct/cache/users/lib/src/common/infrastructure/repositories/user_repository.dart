// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/request/edit_profile.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:users_sdk/src/common/models/response/weak_concepts_response.dart';
import 'package:users_sdk/src/common/services/session_end_hooks.dart';

class UserRepository implements UserRepositoryFacade {
  /// Universal platform gateway: every backend call is a POST to the single
  /// gateway endpoint with a prefix-free `cmd`. Cmds are the users module's
  /// `manifest.json` whitelisted-method keys with the app segment dropped
  /// (`api.user.*`).
  static const _gateway = PlatformGateway();

  /// Cross-session weak concepts for the logged-in student
  /// (`api.user.get_weak_concepts`, Users PR #17).
  ///
  /// Not on [UserRepositoryFacade]: the facade lives in base_sdk (core
  /// repo), so extending it is a core change. Callers that need this
  /// endpoint construct/receive the concrete [UserRepository] — the same
  /// way host glue already instantiates SDK adapters directly.
  ///
  /// Params are clamped client-side to the server's documented ranges
  /// (limit 1..100, offset >= 0, days 1..365); the server clamps again.
  /// A success with `sourceAvailable == false` and no concepts is a valid
  /// state (lms module not composed), NOT a failure.
  Future<ApiResult<WeakConceptsResponse>> getWeakConcepts({
    int limit = 20,
    int offset = 0,
    int days = 90,
  }) async {
    final data = {
      'limit': limit.clamp(1, 100),
      'offset': offset < 0 ? 0 : offset,
      'days': days.clamp(1, 365),
    };
    try {
      final response = await _gateway.tenant(
        'api.user.get_weak_concepts',
        data,
      );
      return ApiResult.success(
        data: WeakConceptsResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get weak concepts failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> getProfileDetails() async {
    try {
      final response = await _gateway.tenant('api.user.get_user_profile');
      return ApiResult.success(data: ProfileResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> get user details failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> saveLocation({
    required AddressNewModel? address,
  }) async {
    try {
      await _gateway.tenant(
        'api.user.add_user_address',
        address?.toJson(),
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> updateLocation({
    required AddressNewModel? address,
    required String? addressId,
  }) async {
    try {
      await _gateway.tenant(
        'api.user.update_user_address',
        {'name': addressId, 'address_data': address?.toJson()},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> deleteAddress({required String id}) async {
    try {
      await _gateway.tenant(
        'api.user.delete_user_address',
        {'name': id},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> logoutAccount({required String fcm}) async {
    try {
      // Before the token goes: the restore-key revoke rides the session
      // that logout is about to end, and a signed-out user whose restore
      // key survived would be signed back in by their next device.
      await SessionEndHooks.run();
      await _gateway.tenant('api.user.logout');
      LocalStorage.logout();
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> editProfile({
    required EditProfile? user,
  }) async {
    final data = user?.toJson();
    try {
      final response = await _gateway.tenant(
        'api.user.update_user_profile',
        {'profile_data': data},
      );
      return ApiResult.success(data: ProfileResponse.fromJson(response));
    } catch (e) {
      debugPrint('==> update profile details failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<WalletHistoriesResponse>> getWalletHistories(
    int page,
  ) async {
    final data = {'limit_start': (page - 1) * 10, 'limit_page_length': 10};
    try {
      final response = await _gateway.tenant(
        'api.user.get_wallet_history',
        data,
      );
      return ApiResult.success(
        data: WalletHistoriesResponse.fromJson(response),
      );
    } catch (e) {
      debugPrint('==> get wallet histories failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> updateFirebaseToken(String? token) async {
    final data = {
      'device_token': token,
      'provider': 'fcm', // Assuming FCM
    };
    try {
      await _gateway.tenant(
        'api.user.register_device_token',
        data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update firebase token failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ReferralModel>> getReferralDetails() async {
    try {
      final response = await _gateway.tenant('api.user.get_referral_details');
      // FrappeResponseInterceptor has already unwrapped the top-level
      // 'message' key, so the gateway's return value is the endpoint
      // payload itself. The backend returns {'referral': null, 'detail':
      // ...} while no referral program is configured; a configured program
      // would put a ReferralModel-shaped map under 'referral'.
      final data = response;
      final referral = data is Map ? data['referral'] : null;
      if (referral is Map) {
        return ApiResult.success(
          data: ReferralModel.fromJson(Map<String, dynamic>.from(referral)),
        );
      }
      // Feature-absent state: no referral program configured on the
      // backend. Return an inactive model instead of crashing in fromJson.
      return ApiResult.success(data: ReferralModel(active: false));
    } catch (e) {
      debugPrint('==> get referral details failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> setActiveAddress({required String id}) async {
    try {
      await _gateway.tenant(
        'api.user.set_active_address',
        {'name': id},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult> deleteAccount() async {
    try {
      // Same reason as logout, and more pressing: a deleted account must
      // not leave a restore key behind that a new device could replay.
      await SessionEndHooks.run();
      await _gateway.tenant('api.user.delete_account');
      LocalStorage.logout();
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> updateProfileImage({
    required String firstName,
    required String imageUrl,
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.user.update_profile_image',
        {'image_url': imageUrl},
      );
      return ApiResult.success(data: ProfileResponse.fromJson(response));
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> updatePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _gateway.tenant(
        'api.user.update_password',
        {'password': password},
      );
      return ApiResult.success(data: ProfileResponse.fromJson(response));
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<dynamic> searchUser({required String name, required int page}) async {
    try {
      final response = await _gateway.tenant(
        'api.user.search_user',
        {'name': name, 'page': page},
      );
      // This is used for wallet transfers, return data as expected by UI
      return response['message'];
    } catch (e) {
      debugPrint('==> search user failure: $e');
      return null;
    }
  }
}
