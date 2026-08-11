import 'package:flutter/material.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/domain/interface/delivery_points.dart';
import 'package:base_sdk/src/models/data/delivery_point_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class DeliveryPointsRepository implements DeliveryPointsRepositoryFacade {
  /// Fetches delivery points near a specific location.
  @override
  Future<ApiResult<List<DeliveryPointData>>> getDeliveryPoints({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.doctype.delivery_point.delivery_point.get_nearest_delivery_points',
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );
      final List<dynamic> data = response.data['message'];
      final List<DeliveryPointData> deliveryPoints =
          data.map((e) => DeliveryPointData.fromJson(e)).toList();
      return ApiResult.success(data: deliveryPoints);
    } catch (e) {
      debugPrint('==> get delivery points failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  /// Fetches all active delivery points, regardless of location.
  @override
  Future<ApiResult<List<DeliveryPointData>>> getAllDeliveryPoints() async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/paas.api.get_delivery_points',
      );
      final List<dynamic> data = response.data['message'];
      final List<DeliveryPointData> deliveryPoints =
          data.map((e) => DeliveryPointData.fromJson(e)).toList();
      return ApiResult.success(data: deliveryPoints);
    } catch (e) {
      debugPrint('==> get all delivery points failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
