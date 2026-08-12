// Shrunken in migration stage M2 - see domain/interface/user_repository.dart
// for what survives here and why, and domain/di/dependency_manager.dart for
// the exit plan. Endpoints stay on the legacy Laravel /api/v1 dashboard
// paths (docs/fork-endpoint-handoff.md).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:driver/domain/di/dependency_manager.dart';
import 'package:driver/domain/interface/interfaces.dart';
import 'package:driver/infrastructure/services/services.dart';

import '../models/response/profile_response.dart';
import '../models/response/request_model_response.dart';

class UserRepositoryImpl implements UserRepository {
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
}
