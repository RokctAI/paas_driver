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
        // add_user_address(address_data) takes the address as one
        // argument, same as AddressRepository.saveAddress.
        {'address_data': address?.toJson()},
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
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    } finally {
      // THE LOCAL SESSION ENDS ON BOTH PATHS, AND THAT IS THE WHOLE POINT
      // OF THE `finally`.
      //
      // Revoking the token server-side is a courtesy; forgetting it on the
      // device is the sign-out. This used to sit on the success path only,
      // so a revoke that threw -- no network, a 401 on an already-dead
      // token, a backend that is down -- returned failure and left the
      // user signed in with everything the session had put on the device.
      //
      // The case that made it certain rather than unlucky: an offline /
      // temp-local account's token is `offline:<local user id>`
      // (auth_sdk's OfflineAuthService), which no backend has ever issued,
      // so `api.user.logout` can NEVER succeed for one of those users.
      // Sign-out was therefore a guaranteed no-op for exactly the users
      // who only ever have local data -- Ray, 2026-09-19: "if on temp
      // local user you logout all your tasks still show".
      //
      // The returned result still reports what the revoke did, so a caller
      // that wants to tell the user "we could not reach the server" keeps
      // its failure; it just no longer decides whether the device forgets
      // the session. SessionEndHooks above has already run by this point,
      // on both paths, for the same reason.
      LocalStorage.logout();
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
    // get_wallet_history(start, limit): the Frappe list-style keys were
    // silently dropped, so every page returned the first 20 rows.
    final data = {'start': (page - 1) * 10, 'limit': 10};
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
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    } finally {
      // Unconditional for the same reason as [logoutAccount], and it has to
      // move with it: [SessionEndHooks.run] above has already torn down the
      // session-scoped state (the restore key, and now each SDK's on-device
      // user data) before the request goes out. Leaving a live local
      // session behind a delete that failed would mean a signed-in user
      // whose session-scoped state is already gone -- strictly worse than
      // being signed out and asked to try again. The returned result still
      // carries the failure, so the caller still reports it.
      LocalStorage.logout();
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> updateProfileImage({
    required String firstName,
    required String imageUrl,
  }) async {
    try {
      // Server signature: update_profile_image(image) -> update_profile(
      // images=image). The old `image_url` key was silently dropped by
      // frappe's kwargs binding and the call TypeErrored on the missing
      // positional `image` (Dart SDK audit 2026-09-02, U1).
      final response = await _gateway.tenant(
        'api.user.update_profile_image',
        {'image': imageUrl},
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
      // Server signature: update_password(password, password_confirmation)
      // and it throws "Password confirmation does not match." when the two
      // differ, so the confirmation the facade already receives must ride
      // along (Dart SDK audit 2026-09-02, U2). Callers keep their own
      // client-side equality check; this only stops the server-side
      // TypeError on the missing positional.
      final response = await _gateway.tenant(
        'api.user.update_password',
        {'password': password, 'password_confirmation': passwordConfirmation},
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
