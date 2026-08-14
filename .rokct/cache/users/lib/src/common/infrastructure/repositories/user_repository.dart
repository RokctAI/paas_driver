import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/request/edit_profile.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:users_sdk/src/common/models/response/weak_concepts_response.dart';

class UserRepository implements UserRepositoryFacade {
  /// Cross-session weak concepts for the logged-in student
  /// (`paas.api.user.get_weak_concepts`, Users PR #17).
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.user.get_weak_concepts',
        data: data,
      );
      return ApiResult.success(
        data: WeakConceptsResponse.fromJson(response.data),
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.user.get_user_profile',
      );
      return ApiResult.success(data: ProfileResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.user.add_user_address',
        data: address?.toJson(),
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
      final client = dioHttp.client(requireAuth: true);
      await client.put(
        '/api/method/paas.api.user.update_user_address',
        data: {'name': addressId, 'address_data': address?.toJson()},
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.user.delete_user_address',
        data: {'name': id},
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
      final client = dioHttp.client(requireAuth: true);
      await client.post('/api/method/paas.api.user.logout');
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/method/paas.api.user.update_user_profile',
        data: {'profile_data': data},
      );
      return ApiResult.success(data: ProfileResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.user.get_wallet_history',
        data: data,
      );
      return ApiResult.success(
        data: WalletHistoriesResponse.fromJson(response.data),
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.user.register_device_token',
        data: data,
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.user.get_referral_details',
      );
      // FrappeResponseInterceptor has already unwrapped the top-level
      // 'message' key, so response.data is the endpoint payload itself.
      // The backend returns {'referral': null, 'detail': ...} while no
      // referral program is configured; a configured program would put a
      // ReferralModel-shaped map under 'referral'.
      final data = response.data;
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
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/method/paas.api.user.set_active_address',
        data: {'name': id},
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
      final client = dioHttp.client(requireAuth: true);
      await client.post('/api/method/paas.api.user.delete_account');
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/method/paas.api.user.update_profile_image',
        data: {'image_url': imageUrl},
      );
      return ApiResult.success(data: ProfileResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.user.update_password',
        data: {'password': password},
      );
      return ApiResult.success(data: ProfileResponse.fromJson(response.data));
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
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/method/paas.api.user.search_user',
        data: {'name': name, 'page': page},
      );
      // This is used for wallet transfers, return data as expected by UI
      return response.data['message'];
    } catch (e) {
      debugPrint('==> search user failure: $e');
      return null;
    }
  }
}
