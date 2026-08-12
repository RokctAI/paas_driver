import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/response/driver_show_response.dart';
import 'package:base_sdk/src/models/response/profile_response.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/delivery_vehicle_type.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/response/request_model_response.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

/// The deliveryman slice of paas_driver's legacy `UserRepositoryImpl`,
/// moved AS-IS (decision D2): still the Laravel
/// `/api/v1/dashboard/deliveryman/*` + `/dashboard/user/request-models`
/// endpoints, unchanged bodies. Endpoint inventory recorded in paas_driver's
/// docs/fork-endpoint-handoff.md.
class CourierRepository implements CourierRepositoryFacade {
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
          "location": {
            'latitude': location.latitude,
            'longitude': location.longitude,
          }
        },
      );
      CourierStorage.setDeliveryInfo(DeliveryResponse.fromJson(res.data));
      return const ApiResult.success(
        data: null,
      );
    } catch (e, s) {
      debugPrint('===> error location settings $e,$s');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }

  @override
  Future<ApiResult<List<List<double>>>> getDeliveryZone() async {
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
      final List<List<double>> zone = response.data['data'] == null
          ? []
          : List<List<double>>.from((response.data['data'] as List).map(
              (x) => List<double>.from((x as List).map(
                    (v) => (v as num).toDouble(),
                  ))));
      return ApiResult.success(data: zone);
    } catch (e) {
      debugPrint('===> error get delivery zone $e');
      return ApiResult.failure(
          error: AppHelpers.errorHandler(e),
          statusCode: NetworkExceptions.getDioStatus(e));
    }
  }
}
