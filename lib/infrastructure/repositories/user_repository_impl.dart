import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/infrastructure/services/services.dart';
import 'package:driver/domain/di/dependency_manager.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:driver/domain/interface/interfaces.dart';
import '../models/data/delivery_vehicle_type.dart';
import '../models/models.dart';

class UserRepositoryImpl implements UserRepository {
  @override
  Future<ApiResult<DeliveryResponse>> getDriverDetails() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/settings',
      );
      return ApiResult.success(
        data: DeliveryResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('===> error driver settings $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<DeliveryVehicleType>>> getDeliveryVehicleTypes() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get('/api/v1/rest/delivery-vehicle-types');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        final items =
            data.map((item) => DeliveryVehicleType.fromJson(item)).toList();
        return ApiResult.success(data: items);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to load vehicle types',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      return ApiResult.failure(
        error: e.response?.data['message'] ?? e.message,
        statusCode: e.response?.statusCode ?? 0,
      );
    } catch (e) {
      return ApiResult.failure(
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> updateGeneralInfo({
    required String firstName,
    String? lastName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
  }) async {
    final data = {
      'firstname': firstName,
      if (lastName != null) 'lastname': lastName,
      if (phone != null) 'phone': phone.replaceAll("+", ""),
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (confirmPassword != null) 'password_confirmation': confirmPassword,
    };
    debugPrint('===> update general info data ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/v1/dashboard/user/profile/update',
        data: data,
      );
      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> update profile details failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> getProfileDetails() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/user/profile/show',
      );

      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> editProfile({
    required EditProfile? user,
  }) async {
    final data = user?.toJson();
    debugPrint('===> update general info data ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/v1/dashboard/user/profile/update',
        data: data,
      );
      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> update profile details failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> updateProfileImage({
    String? firstName,
    String? imageUrl,
  }) async {
    final data = {
      'firstname': firstName,
      'images': [imageUrl],
    };
    debugPrint('===> update profile image data ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/v1/dashboard/user/profile/update',
        data: data,
      );
      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> update profile image failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> updatePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = {
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/dashboard/user/profile/password/update',
        data: data,
      );
      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> update password failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<void>> updateFirebaseToken(String? token) async {
    final data = {if (token != null) 'firebase_token': token};
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/user/profile/firebase/token/update',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update firebase token failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<DeliveryResponse>> editCarInfo(
      {required String type,
      required String brand,
      required String model,
      required String number,
      required String color,
      required String height,
      required String weight,
      required String length,
      required String width,
      String? imageUrl}) async {
    final data = {
      'type_of_technique': type,
      'brand': brand,
      'model': model,
      'number': number,
      'color': color,
      if (height.trim().isNotEmpty) 'height': int.tryParse(height),
      if (width.trim().isNotEmpty) 'width': int.tryParse(width),
      if (weight.trim().isNotEmpty) 'kg': int.tryParse(weight),
      if (length.trim().isNotEmpty) 'length': int.tryParse(length),
      "online": (LocalStorage.getUser()?.active ?? false) ? 1 : 0,
      if (imageUrl != null) 'images[0]': imageUrl,
    };
    debugPrint('===> update car info data ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/dashboard/deliveryman/settings',
        data: data,
      );
      return ApiResult.success(
        data: DeliveryResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> update car details failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<DeliveryResponse>> createCarInfo(
      {required String type,
      required String brand,
      required String model,
      required String number,
      required String color,
      required String height,
      required String weight,
      required String length,
      required String width,
      String? imageUrl}) async {
    final data = {
      "data": {
        "type_of_technique": type,
        "brand": brand,
        "model": model,
        "number": number,
        "color": color,
        'height': int.tryParse(height) ?? 0,
        'width': int.tryParse(width) ?? 0,
        'kg': int.tryParse(weight) ?? 0,
        'length': int.tryParse(length) ?? 0,
        "online": (LocalStorage.getUser()?.active ?? false) ? 1 : 0,
        if (imageUrl != null) 'images[0]': imageUrl,
      }
    };
    debugPrint('===> create car info data ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/dashboard/user/request-models',
        data: data,
      );
      return ApiResult.success(
        data: DeliveryResponse.fromJson(response.data['data']),
      );
    } catch (e, s) {
      debugPrint('==> create car details failure: $e.$s');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  // getStatistics / getStatisticsOrder / getDriverStatistics moved to
  // revenue_sdk's CourierStatisticsRepository (src/driver/, corporate main).

  @override
  Future<ApiResult> setOnline() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/deliveryman/settings/online',
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update online token failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<RequestModelResponse>> getRequestModel() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final res = await client.get(
        '/api/v1/dashboard/user/request-models',
      );
      return ApiResult.success(data: RequestModelResponse.fromJson(res.data));
    } catch (e) {
      debugPrint('==> get request model failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult> setCurrentLocation(LatLng location) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final res = await client.post(
        '/api/v1/dashboard/deliveryman/settings/location',
        data: {
          "location": LocalLocationData(
                  latitude: location.latitude, longitude: location.longitude)
              .toJson()
        },
      );
      LocalStorage.setDeliveryInfo(DeliveryResponse.fromJson(res.data));
      return const ApiResult.success(
        data: null,
      );
    } catch (e, s) {
      debugPrint('===> error statistics settings $e,$s');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult> deleteAccount() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.delete(
        '/api/v1/dashboard/user/profile/delete',
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<LatLng> points,
  }) async {
    List<Map<String, dynamic>> tapped = [];
    for (final point in points) {
      final location = {'0': point.latitude, '1': point.longitude};
      tapped.add(location);
    }
    final data = {
      'address': tapped,
    };
    debugPrint('====> update delivery zone ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/deliveryman/delivery-zones',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update delivery zones failure: $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<DeliveryZonePaginate>> getDeliveryZone() async {
    final data = {
      'lang': LocalStorage.getLanguage()?.locale,
      'currency_id': LocalStorage.getSelectedCurrency()?.id,
      'perPage': 1,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/deliveryman/delivery-zones',
        queryParameters: data,
      );
      return ApiResult.success(
        data: DeliveryZonePaginate.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('===> error get delivery zone $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }
}
