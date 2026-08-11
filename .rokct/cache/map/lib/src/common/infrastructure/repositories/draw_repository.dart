import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:base_sdk/src/models/response/draw_routing_response.dart';
import 'package:base_sdk/src/constants/app_constants.dart';

import 'package:base_sdk/src/handlers/api_result.dart';

class DrawRepository implements DrawRepositoryFacade {
  @override
  Future<ApiResult<DrawRouting>> getRouting({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false, routing: true);
      final response = await client.get(
        '/v2/directions/driving-car',
        queryParameters: {
          "api_key": AppConstants.routingKey,
          "start": (start.longitude, start.latitude),
          "end": (end.longitude, end.latitude),
        },
      );
      return ApiResult.success(data: DrawRouting.fromJson(response.data));
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
